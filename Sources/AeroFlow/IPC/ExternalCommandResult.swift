// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM
// Copyright (C) 2026 Timur Iskakov — https://github.com/frostymur

import Foundation

enum ExternalCommandResult: Equatable, Sendable, Error {
    case executed
    case ignoredDisabled
    case ignoredLayoutMismatch
    case staleWindowId
    case workspaceAssignmentConflict
    case workspaceStateConflict
    case notFound
    case noChange
    case windowActionFailed
    case invalidArguments
}
