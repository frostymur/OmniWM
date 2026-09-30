// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM
// Copyright (C) 2026 Timur Iskakov — https://github.com/frostymur

import CoreGraphics
import Foundation

@MainActor
struct WorldView {
    private let controller: WMController
    private let liveBoundsProvider: ((Int) -> CGRect?)?

    /// Creates a world view over the window-manager controller.
    /// - Parameters:
    ///   - controller: The window manager this view reads state from.
    ///   - liveBoundsProvider: Injectable source of live window bounds (defaults to
    ///     querying the WindowServer); lets tests supply synthetic bounds.
    init(
        controller: WMController,
        liveBoundsProvider: ((Int) -> CGRect?)? = nil
    ) {
        self.controller = controller
        self.liveBoundsProvider = liveBoundsProvider
    }

    var hasStartedServices: Bool {
        controller.hasStartedServices
    }

    var monitors: [Monitor] {
        controller.workspaceManager.monitors
    }

    var renderableFocusToken: WindowToken? {
        controller.workspaceManager.renderableFocusToken
    }

    var borderFocusToken: WindowToken? {
        controller.workspaceManager.borderFocusToken
    }

    var systemModalFocusToken: WindowToken? {
        controller.workspaceManager.systemModalFocusToken
    }

    func hasPendingNativeFullscreenTransition(for token: WindowToken) -> Bool {
        controller.workspaceManager.hasPendingNativeFullscreenTransition(for: token)
    }

    func hasPendingNativeFullscreenTransition(in workspaceId: WorkspaceDescriptor.ID) -> Bool {
        controller.workspaceManager.hasPendingNativeFullscreenTransition(in: workspaceId)
    }

    var spaceTopology: SpaceTopology {
        controller.workspaceManager.spaceTopology
    }

    func entry(for token: WindowToken) -> WindowState? {
        controller.workspaceManager.entry(for: token)
    }

    func isWindowFullscreenInLayout(_ token: WindowToken) -> Bool {
        guard let entry = controller.workspaceManager.entry(for: token) else { return false }
        switch controller.workspaceManager.activeLayoutKind(for: entry.workspaceId) {
        case .dwindle:
            return controller.dwindleEngine?.isWindowFullscreen(token, in: entry.workspaceId) == true
        case .niri:
            return controller.niriEngine?.isWindowFullscreen(token, in: entry.workspaceId) == true
        }
    }

    func isManagedWindowDisplayable(_ token: WindowToken) -> Bool {
        controller.isManagedWindowDisplayable(token)
    }

    func isWorkspaceVisible(_ workspaceId: WorkspaceDescriptor.ID) -> Bool {
        controller.workspaceManager.visibleWorkspaceIds().contains(workspaceId)
    }

    func tabRailInfos() -> [TabRailInfo] {
        var infos = controller.niriLayoutHandler.desiredTabRailInfos()
        infos.append(contentsOf: controller.dwindleLayoutHandler.desiredTabRailInfos())
        return infos
    }

    var tabRailStyle: TabRailStyle {
        controller.tabRailStyle
    }

    func nativeFullscreenPlaceholders() -> [NativeFullscreenPlaceholderUpdate] {
        let workspaceManager = controller.workspaceManager
        var updates: [NativeFullscreenPlaceholderUpdate] = []
        for record in workspaceManager.nativeFullscreenRecordsByOriginalToken.values {
            let entry = workspaceManager.entry(for: record.currentToken)
            updates.append(
                NativeFullscreenPlaceholderUpdate(
                    originalToken: record.originalToken,
                    currentToken: record.currentToken,
                    workspaceId: record.workspaceId,
                    windowTitle: entry?.managedReplacementMetadata?.title ?? "",
                    frame: .zero,
                    displayContext: nil,
                    selected: workspaceManager.selectedManagedToken == record.currentToken
                        || workspaceManager.pendingFocusedToken == record.currentToken,
                    visible: record.transition == .suspended
                        && entry?.layoutReason == .nativeFullscreen
                        && entry.map(isPlaceholderDescriptorVisible(entry:)) == true
                )
            )
        }
        updates.sort {
            ($0.originalToken.pid, $0.originalToken.windowId) < ($1.originalToken.pid, $1.originalToken.windowId)
        }
        return updates
    }

    private func isPlaceholderDescriptorVisible(entry: WindowState) -> Bool {
        let workspaceManager = controller.workspaceManager
        guard isWorkspaceVisible(entry.workspaceId),
              !workspaceManager.isWindowSuppressedByMacOS(entry.token),
              !workspaceManager.isHiddenInCorner(entry.token)
        else { return false }
        guard spaceTopology.isPopulated,
              let monitor = workspaceManager.monitor(for: entry.workspaceId),
              spaceTopology.isDisplayShowingFullscreenSpace(on: monitor) == false
        else { return false }
        return true
    }

}
