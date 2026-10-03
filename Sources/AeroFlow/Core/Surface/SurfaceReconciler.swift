// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM
// Copyright (C) 2026 Timur Iskakov — https://github.com/frostymur

import CoreGraphics
import Foundation

@MainActor
final class SurfaceReconciler {
    typealias TabRailApply = @MainActor (WMController, [TabRailInfo], Bool) -> Void
    typealias NativeFullscreenPlaceholderApply = @MainActor (
        WMController,
        [NativeFullscreenPlaceholderUpdate],
        Bool
    ) -> Void

    private weak var controller: WMController?
    private(set) var reconcileScheduled = false
    private(set) var forceOrderingOnNextReconcile = false
    private let parkingEdgeMaskManager = ParkingEdgeMaskManager()
    private let applyTabRails: TabRailApply
    private let applyNativeFullscreenPlaceholders: NativeFullscreenPlaceholderApply
    let nativeFullscreenState = NativeFullscreenSurfaceState()
    private(set) var appliedScene = DesiredSurfaceScene.empty

    func nativeFullscreenDiagnosticsSnapshot() -> FullscreenSurfaceDiagnosticsSnapshot {
        nativeFullscreenState.diagnostics(applied: appliedScene.placeholders, controller: controller)
    }

    init(
        controller: WMController,
        applyTabRails: @escaping TabRailApply = { controller, infos, forceOrdering in
            controller.tabRailManager.updateRails(
                infos, forceOrdering: forceOrdering, style: controller.tabRailStyle
            )
        },
        applyNativeFullscreenPlaceholders: @escaping NativeFullscreenPlaceholderApply = {
            controller,
            placeholders,
            forceOrdering in
            controller.nativeFullscreenPlaceholderManager.apply(
                placeholders,
                forceOrdering: forceOrdering
            )
        }
    ) {
        self.controller = controller
        self.applyTabRails = applyTabRails
        self.applyNativeFullscreenPlaceholders = applyNativeFullscreenPlaceholders
    }

    func noteWorldChanged() {
        scheduleReconcile()
    }

    private func scheduleReconcile() {
        guard !reconcileScheduled else { return }
        reconcileScheduled = true
        let mainRunLoop = CFRunLoopGetMain()
        CFRunLoopPerformBlock(mainRunLoop, CFRunLoopMode.commonModes.rawValue) {
            MainActor.assumeIsolated {
                self.flushScheduledReconcile()
            }
        }
        CFRunLoopWakeUp(mainRunLoop)
    }

    func noteRestackOccurred() {
        forceOrderingOnNextReconcile = true
        noteWorldChanged()
    }

    func reconcileNow() {
        let forceOrdering = forceOrderingOnNextReconcile
        reconcileScheduled = false
        forceOrderingOnNextReconcile = false
        runFullReconcile(forceOrdering: forceOrdering)
    }

    func applyAcceptedNativeFullscreenSlots(
        _ slots: [WindowToken: NativeFullscreenSlotProjection],
        workspaceId: WorkspaceDescriptor.ID,
        displayId: CGDirectDisplayID,
        displayContext: NativeFullscreenDisplayContext
    ) {
        guard let controller else { return }
        let update = NativeFullscreenSurfaceProjectionUpdate(
            slots: slots,
            workspaceId: workspaceId,
            displayId: displayId,
            displayContext: displayContext
        )
        guard nativeFullscreenState.accept(update, controller: controller) else { return }

        var needsManagerApply = false
        for index in appliedScene.placeholders.indices {
            let previous = appliedScene.placeholders[index]
            guard previous.workspaceId == workspaceId,
                  let descriptor = nativeFullscreenState.descriptor(for: previous.originalToken)
            else { continue }

            let resolution = nativeFullscreenState.resolvedNativeFullscreenPlaceholder(
                descriptor,
                previous: previous,
                controller: controller
            )
            let next = resolution.update
            guard next != previous else { continue }

            appliedScene.placeholders[index] = next
            NativeFullscreenSurfaceTrace.traceSurfaceAppliedIfSignificant(
                next,
                previous: previous,
                reason: resolution.reason
            )
            if previous.originalToken == next.originalToken,
               previous.currentToken == next.currentToken,
               previous.workspaceId == next.workspaceId,
               previous.selected == next.selected,
               previous.visible == next.visible
            {
                controller.nativeFullscreenPlaceholderManager.moveForAnimation(next)
            } else {
                needsManagerApply = true
            }
        }

        if needsManagerApply {
            controller.nativeFullscreenPlaceholderManager.apply(appliedScene.placeholders)
        }
    }

    func applyAcceptedTabRailGeometry(
        _ commands: [TabRailGeometryCommand],
        workspaceId: WorkspaceDescriptor.ID,
        displayId: CGDirectDisplayID
    ) {
        guard !commands.isEmpty,
              let controller,
              controller.hasStartedServices,
              let monitor = controller.workspaceManager.monitor(for: workspaceId),
              monitor.displayId == displayId,
              controller.workspaceManager.activeWorkspaceOrFirst(on: monitor.id)?.id == workspaceId
        else {
            return
        }
        controller.tabRailManager.applyAnimationGeometry(commands, in: workspaceId)
    }

    func cleanup() {
        reconcileScheduled = false
        forceOrderingOnNextReconcile = false
        parkingEdgeMaskManager.removeAll()
        nativeFullscreenState.cleanup()
        appliedScene = .empty
    }

    private func flushScheduledReconcile() {
        guard reconcileScheduled else { return }
        reconcileNow()
    }

    private func runFullReconcile(forceOrdering: Bool) {
        guard let controller else { return }
        let world = WorldView(controller: controller)
        nativeFullscreenState.prepareForReconcile(
            servicesStarted: world.hasStartedServices,
            workspaceManager: controller.workspaceManager
        )
        var desired = SurfaceDerivation.derive(world: world)
        nativeFullscreenState.replaceDescriptors(desired.placeholders)
        desired.placeholders = desired.placeholders.map { descriptor in
            let previous = appliedScene.placeholders.first {
                $0.originalToken == descriptor.originalToken
            }
            let resolution = nativeFullscreenState.resolvedNativeFullscreenPlaceholder(
                descriptor,
                previous: previous,
                controller: controller
            )
            let resolved = resolution.update
            if resolved != previous {
                NativeFullscreenSurfaceTrace.traceSurfaceAppliedIfSignificant(
                    resolved,
                    previous: previous,
                    reason: resolution.reason
                )
            }
            return resolved
        }
        applyFull(
            desired,
            on: controller,
            forceOrdering: forceOrdering
        )
    }

    private func applyFull(
        _ desired: DesiredSurfaceScene,
        on controller: WMController,
        forceOrdering: Bool
    ) {
        if desired.tabRails != appliedScene.tabRails || desired.tabRailStyle != appliedScene
            .tabRailStyle || forceOrdering
        {
            applyTabRails(controller, desired.tabRails, forceOrdering)
        }
        if desired.placeholders != appliedScene.placeholders || forceOrdering {
            applyNativeFullscreenPlaceholders(controller, desired.placeholders, forceOrdering)
        }
        parkingEdgeMaskManager.apply(desired.parkingEdgeMasks)
        appliedScene = desired
    }
}
