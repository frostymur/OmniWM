// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM
// Copyright (C) 2026 Timur Iskakov — https://github.com/frostymur

import AppKit
import Foundation
import AeroFlowIPC

extension WMController {
    func isManagedWindowDisplayable(_ token: WindowToken) -> Bool {
        guard workspaceManager.entry(for: token) != nil else { return false }
        if isManagedWindowSuppressedByMacOS(token) {
            return false
        }
        if workspaceManager.layoutReason(for: token) != .standard {
            return false
        }
        return !workspaceManager.isHiddenInCorner(token)
    }

    func isManagedWindowSuppressedByMacOS(_ token: WindowToken) -> Bool {
        workspaceManager.isWindowSuppressedByMacOS(token)
    }

    func isManagedWindowSuspendedForNativeFullscreen(_ token: WindowToken) -> Bool {
        workspaceManager.isNativeFullscreenSuspended(token)
    }

    func monitorForInteraction() -> Monitor? {
        placementResolver.monitorForInteraction()
    }

    func interactionWorkspaceProjection() -> (monitor: Monitor?, workspace: WorkspaceDescriptor?) {
        let monitor = monitorForInteraction()
        return (monitor, monitor.flatMap { workspaceManager.activeWorkspace(on: $0.id) })
    }

    func activeWorkspace() -> WorkspaceDescriptor? {
        guard let monitor = monitorForInteraction() else { return nil }
        return workspaceManager.activeWorkspaceOrFirst(on: monitor.id)
    }

    func focusedOrFrontmostWindowTokenForAutomation(
        preferFrontmostWhenExternalOrOwnedFocusActive: Bool = false
    ) -> WindowToken? {
        let selectedManagedToken = workspaceManager.selectedManagedToken
        let frontmostPid = commandHandler.frontmostAppPidProvider?()
            ?? NSWorkspace.shared.frontmostApplication?.processIdentifier
        let frontmostToken = commandHandler.frontmostFocusedWindowTokenProvider?()
            ?? frontmostPid.flatMap { axEventHandler.focusedWindowToken(for: $0) }
        if preferFrontmostWhenExternalOrOwnedFocusActive {
            switch workspaceManager.nativeFocusOwner {
            case .external,
                 .ownedSurface:
                return frontmostToken ?? selectedManagedToken
            case .managed,
                 .none:
                break
            }
        }
        return selectedManagedToken ?? frontmostToken
    }

    func focusedManagedTokenForCommand() -> WindowToken? {
        let token = focusedOrFrontmostWindowTokenForAutomation()
        guard let token,
              workspaceManager.entry(for: token) != nil,
              !workspaceManager.isWindowSuppressedByMacOS(token)
        else {
            return nil
        }
        return token
    }

    func runningAppsWithWindows() -> [RunningAppInfo] {
        windowActionHandler.runningAppsWithWindows()
    }

    func runningAppsForRulePicker() -> [RunningAppInfo] {
        RunningAppInventory.rulePickerCandidates(trackedApplications: runningAppsWithWindows())
    }
}
