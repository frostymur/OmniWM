// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM
// Copyright (C) 2026 Timur Iskakov — https://github.com/frostymur

import AppKit
import Foundation

struct FullRescanLayoutRequest {
    let removalPayloads: [LayoutRefreshController.WindowRemovalPayload]
    let relayoutWorkspaceIds: Set<WorkspaceDescriptor.ID>?
    let postLayoutActions: [RefreshPostLayoutAction]
    let postLayoutActionWorkspacesCurrentAtMutation: [Set<WorkspaceDescriptor.ID>]
}
