// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM
// Copyright (C) 2026 Timur Iskakov — https://github.com/frostymur

import Foundation

enum AeroFlowFocusNotificationKey {
    static let oldWorkspaceId = "oldWorkspaceId"
    static let newWorkspaceId = "newWorkspaceId"
    static let oldWorkspaceName = "oldWorkspaceName"
    static let newWorkspaceName = "newWorkspaceName"
    static let oldMonitorIndex = "oldMonitorIndex"
    static let newMonitorIndex = "newMonitorIndex"
    static let oldMonitorName = "oldMonitorName"
    static let newMonitorName = "newMonitorName"
    static let oldWindowId = "oldWindowId"
    static let newWindowId = "newWindowId"
    static let oldWindowToken = "oldWindowToken"
    static let newWindowToken = "newWindowToken"
    static let oldHandleId = "oldHandleId"
    static let newHandleId = "newHandleId"
}

extension Notification.Name {
    static let aeroflowFocusChanged = Notification.Name("AeroFlow.FocusChanged")
    static let aeroflowFocusedWorkspaceChanged = Notification.Name("AeroFlow.FocusedWorkspaceChanged")
    static let aeroflowFocusedMonitorChanged = Notification.Name("AeroFlow.FocusedMonitorChanged")
}

@MainActor
final class FocusNotificationDispatcher {
    struct ChangeSet: Equatable {
        let focusChanged: Bool
        let workspaceChanged: Bool
        let monitorChanged: Bool
    }

    weak var controller: WMController?

    private var lastNotifiedWorkspaceId: WorkspaceDescriptor.ID?
    private var lastNotifiedMonitorId: Monitor.ID?
    private var lastNotifiedFocusedToken: WindowToken?
    private var lastNotifiedFocusedWindowId: Int?

    init(controller: WMController) {
        self.controller = controller
    }

    @discardableResult
    func notifyFocusChangesIfNeeded() -> ChangeSet {
        guard let controller else {
            return ChangeSet(focusChanged: false, workspaceChanged: false, monitorChanged: false)
        }
        let projection = controller.interactionWorkspaceProjection()
        let currentMonitorId = projection.monitor?.id
        let currentWorkspaceId = projection.workspace?.id

        let focusChanged = notifyWindowFocusIfNeeded(controller: controller)
        let workspaceChanged = notifyWorkspaceIfNeeded(currentWorkspaceId, controller: controller)
        let monitorChanged = notifyMonitorIfNeeded(currentMonitorId, controller: controller)

        return ChangeSet(
            focusChanged: focusChanged,
            workspaceChanged: workspaceChanged,
            monitorChanged: monitorChanged
        )
    }

    private func notifyWindowFocusIfNeeded(controller: WMController) -> Bool {
        let currentToken = controller.workspaceManager.nativeManagedFocusToken
        let currentWindowId = currentToken
            .flatMap { controller.workspaceManager.entry(for: $0)?.windowId }

        if currentToken != lastNotifiedFocusedToken || currentWindowId != lastNotifiedFocusedWindowId {
            var info: [AnyHashable: Any] = [:]
            if let oldToken = lastNotifiedFocusedToken {
                info[AeroFlowFocusNotificationKey.oldWindowToken] = oldToken
                info[AeroFlowFocusNotificationKey.oldHandleId] = oldToken
            }
            if let newToken = currentToken {
                info[AeroFlowFocusNotificationKey.newWindowToken] = newToken
                info[AeroFlowFocusNotificationKey.newHandleId] = newToken
            }
            if let oldWindowId = lastNotifiedFocusedWindowId {
                info[AeroFlowFocusNotificationKey.oldWindowId] = oldWindowId
            }
            if let newWindowId = currentWindowId { info[AeroFlowFocusNotificationKey.newWindowId] = newWindowId }

            NotificationCenter.default.post(
                name: .aeroflowFocusChanged,
                object: controller,
                userInfo: info.isEmpty ? nil : info
            )
            lastNotifiedFocusedToken = currentToken
            lastNotifiedFocusedWindowId = currentWindowId
            return true
        }
        return false
    }

    private func notifyWorkspaceIfNeeded(
        _ currentWorkspaceId: WorkspaceDescriptor.ID?,
        controller: WMController
    ) -> Bool {
        var workspaceInfo: [AnyHashable: Any] = [:]
        if let oldId = lastNotifiedWorkspaceId {
            workspaceInfo[AeroFlowFocusNotificationKey.oldWorkspaceId] = oldId
            if let name = controller.workspaceManager.descriptor(for: oldId)?
                .name { workspaceInfo[AeroFlowFocusNotificationKey.oldWorkspaceName] = name }
        }
        if let newId = currentWorkspaceId {
            workspaceInfo[AeroFlowFocusNotificationKey.newWorkspaceId] = newId
            if let name = controller.workspaceManager.descriptor(for: newId)?
                .name { workspaceInfo[AeroFlowFocusNotificationKey.newWorkspaceName] = name }
        }
        return postNotificationIfChanged(
            name: .aeroflowFocusedWorkspaceChanged,
            current: currentWorkspaceId,
            last: &lastNotifiedWorkspaceId,
            info: workspaceInfo,
            sender: controller
        )
    }

    private func notifyMonitorIfNeeded(_ currentMonitorId: Monitor.ID?, controller: WMController) -> Bool {
        var monitorInfo: [AnyHashable: Any] = [:]
        if let oldId = lastNotifiedMonitorId {
            monitorInfo[AeroFlowFocusNotificationKey.oldMonitorIndex] = oldId.displayId
            if let name = controller.workspaceManager.monitor(byId: oldId)?
                .name { monitorInfo[AeroFlowFocusNotificationKey.oldMonitorName] = name }
        }
        if let newId = currentMonitorId {
            monitorInfo[AeroFlowFocusNotificationKey.newMonitorIndex] = newId.displayId
            if let name = controller.workspaceManager.monitor(byId: newId)?
                .name { monitorInfo[AeroFlowFocusNotificationKey.newMonitorName] = name }
        }
        return postNotificationIfChanged(
            name: .aeroflowFocusedMonitorChanged,
            current: currentMonitorId,
            last: &lastNotifiedMonitorId,
            info: monitorInfo,
            sender: controller
        )
    }

    private func postNotificationIfChanged<T: Equatable>(
        name: Notification.Name,
        current: T?,
        last: inout T?,
        info: [AnyHashable: Any],
        sender: AnyObject
    ) -> Bool {
        guard current != last else { return false }
        NotificationCenter.default.post(
            name: name,
            object: sender,
            userInfo: info.isEmpty ? nil : info
        )
        last = current
        return true
    }
}
