// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM
// Copyright (C) 2026 Timur Iskakov — https://github.com/frostymur

import CoreGraphics
import Foundation
import QuartzCore

final class DwindleWorkspaceState {
    let root = DwindleNode(kind: .leaf(tile: nil))
    var leafByToken: [WindowToken: DwindleNode] = [:]
    var excludedTokens: Set<WindowToken> = []
    var tileCount = 0
    var selectedNodeId: DwindleNodeId?
    var preselection: Direction?
    var pendingMovementFrameSeeds: [WindowToken: CGRect] = [:]
}
