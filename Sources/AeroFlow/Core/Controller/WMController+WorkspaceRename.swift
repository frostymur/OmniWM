// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM
// Copyright (C) 2026 Timur Iskakov — https://github.com/frostymur

import Foundation
import AeroFlowIPC

extension WMController {
    func setWorkspaceDisplayName(
        _ displayName: String,
        forWorkspaceNamed rawWorkspaceID: String
    ) -> ExternalCommandResult {
        var configs = settings.workspaces.configurations
        guard let index = configs.firstIndex(where: { $0.name == rawWorkspaceID }) else { return .notFound }
        let normalized: String? = displayName.isEmpty || displayName == rawWorkspaceID ? nil : displayName
        guard configs[index].displayName != normalized else { return .noChange }

        configs[index].displayName = normalized
        settings.workspaces.configurations = configs
        publishWorkspaceDataChanged()
        return .executed
    }
}
