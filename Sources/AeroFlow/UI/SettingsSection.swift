// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM
// Copyright (C) 2026 Timur Iskakov — https://github.com/frostymur

import SwiftUI

enum SettingsSection: String, CaseIterable, Identifiable {
    case general
    case diagnostics
    case niri
    case dwindle
    case monitors
    case workspaces
    case hotkeys
    case mouseTrackpad
    case reportIssue

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .general: String(localized: "General")
        case .diagnostics: String(localized: "Troubleshooting")
        case .niri: String(localized: "Niri Layout")
        case .dwindle: String(localized: "Dwindle Layout")
        case .monitors: String(localized: "Monitors")
        case .workspaces: String(localized: "Workspaces")
        case .hotkeys: String(localized: "Hotkeys")
        case .mouseTrackpad: String(localized: "Mouse & Trackpad")
        case .reportIssue: String(localized: "Report an Issue")
        }
    }

    var icon: String {
        switch self {
        case .general: "gearshape"
        case .diagnostics: "stethoscope"
        case .niri: "scroll"
        case .dwindle: "square.split.2x2"
        case .monitors: "display"
        case .workspaces: "rectangle.3.group"
        case .hotkeys: "keyboard"
        case .mouseTrackpad: "computermouse"
        case .reportIssue: "ladybug"
        }
    }
}

enum SettingsSectionGroup: String, CaseIterable, Identifiable {
    case basics = "Basics"
    case layouts = "Layouts"
    case workspace = "Workspace"
    case input = "Input"
    case help = "Help"

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .basics: String(localized: "Basics")
        case .layouts: String(localized: "Layouts")
        case .workspace: String(localized: "Workspace")
        case .input: String(localized: "Input")
        case .help: String(localized: "Help")
        }
    }

    var sections: [SettingsSection] {
        switch self {
        case .basics:
            [.general]
        case .layouts:
            [.niri, .dwindle, .monitors]
        case .workspace:
            [.workspaces]
        case .input:
            [.hotkeys, .mouseTrackpad]
        case .help:
            [.reportIssue, .diagnostics]
        }
    }
}
