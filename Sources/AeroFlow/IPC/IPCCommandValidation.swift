// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM
// Copyright (C) 2026 Timur Iskakov — https://github.com/frostymur

import Foundation
import AeroFlowIPC

@MainActor
enum IPCCommandValidation {
    static func controllerState(_ controller: WMController) -> ExternalCommandResult? {
        guard controller.isEnabled else { return .ignoredDisabled }
        return nil
    }

    static func workspaceTarget(
        _ target: WorkspaceTarget,
        controller: WMController
    ) -> Result<String, ExternalCommandResult> {
        let resolver = WorkspaceTargetResolver(
            settings: controller.settings,
            workspaceManager: controller.workspaceManager
        )

        switch resolver.resolve(target) {
        case let .success(rawWorkspaceID):
            return .success(rawWorkspaceID)
        case .failure(.notFound):
            return .failure(.notFound)
        case .failure(.invalidTarget),
             .failure(.ambiguousDisplayName):
            return .failure(.invalidArguments)
        }
    }

    static func isAlreadyOnWorkspace(_ token: WindowToken, rawWorkspaceID: String, controller: WMController) -> Bool {
        guard let targetId = controller.workspaceManager.workspaceId(for: rawWorkspaceID, createIfMissing: false)
        else { return false }
        return controller.workspaceManager.workspace(for: token) == targetId
    }
}
