// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM
// Copyright (C) 2026 Timur Iskakov — https://github.com/frostymur

enum TrackpadScrollStyle: String, CaseIterable, Codable, Identifiable {
    case snap
    case momentum

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .snap: "Snap to Columns"
        case .momentum: "Momentum"
        }
    }
}
