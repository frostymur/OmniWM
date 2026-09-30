// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM

import Foundation

enum AnimationStyle: String, Codable, CaseIterable, Sendable {
    case snappy
    case smooth
    case instant
}

extension AnimationStyle {
    var dwindleConfig: CubicConfig {
        switch self {
        case .snappy: .snappy
        case .smooth: .hyprlandDwindle
        case .instant: .instant
        }
    }

    var niriConfig: SpringConfig {
        switch self {
        case .snappy: .snappyWindowMovement
        case .smooth: .niriWindowMovement
        case .instant: .instantWindowMovement
        }
    }
}
