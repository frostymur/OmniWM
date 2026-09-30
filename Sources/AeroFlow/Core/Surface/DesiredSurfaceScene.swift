// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM
// Copyright (C) 2026 Timur Iskakov — https://github.com/frostymur

import CoreGraphics
import Foundation

struct ParkingEdgeMaskKey: Hashable {
    enum Side: String, Hashable {
        case left
        case right
    }

    let monitorId: Monitor.ID
    let side: Side
}

struct DesiredParkingEdgeMask: Equatable {
    let key: ParkingEdgeMaskKey
    let frame: CGRect
}

struct DesiredSurfaceScene: Equatable {
    var tabRails: [TabRailInfo] = []
    var tabRailStyle: TabRailStyle = .compact
    var placeholders: [NativeFullscreenPlaceholderUpdate] = []
    var parkingEdgeMasks: [DesiredParkingEdgeMask] = []

    static let empty = DesiredSurfaceScene()
}
