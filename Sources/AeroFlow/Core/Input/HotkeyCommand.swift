// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM
// Copyright (C) 2026 Timur Iskakov — https://github.com/frostymur

import AeroFlowIPC
import Foundation

struct PhysicalHotkeyTrigger: Equatable, Hashable, Sendable {
    let keyCode: UInt32
    let modifiers: UInt32
    let isRepeat: Bool
}

struct HotkeyInvocation: Equatable, Sendable {
    let command: HotkeyCommand
    let trigger: PhysicalHotkeyTrigger?

    init(command: HotkeyCommand, trigger: PhysicalHotkeyTrigger? = nil) {
        self.command = command
        self.trigger = trigger
    }
}

enum LayoutCompatibility: String {
    case shared = "Shared"
    case niri = "Niri"
    case dwindle = "Dwindle"

    var localizedDisplayName: String {
        Self.localizedNames[self] ?? rawValue
    }

    private static let localizedNames: [LayoutCompatibility: String] = [
        .shared: String(localized: LocalizedStringResource(
            "command.scope.shared", defaultValue: "Shared", table: "Commands", bundle: .aeroFlow
        )),
        .niri: String(localized: LocalizedStringResource(
            "command.scope.niri", defaultValue: "Niri", table: "Commands", bundle: .aeroFlow
        )),
        .dwindle: String(localized: LocalizedStringResource(
            "command.scope.dwindle", defaultValue: "Dwindle", table: "Commands", bundle: .aeroFlow
        ))
    ]
}

enum HotkeyCommand: Equatable, Hashable {
    case focus(Direction)
    case move(Direction)
    case monitorFocus(IPCMonitorFocusCommand)
    case fullscreen(IPCFullscreenCommand)
    case moveColumn(Direction)

    case raiseAllFloatingWindows
    case rescueOffscreenWindows
    case windowState(IPCWindowStateCommand)

    case focusNavigation(FocusNavigationAction)
    case windowMovement(WindowMovementAction)
    case column(ColumnAction)
    case workspace(WorkspaceAction)
    case sizing(SizingAction)
    case dwindle(DwindleAction)

    var displayName: String {
        ActionCatalog.title(for: self) ?? String(describing: self)
    }

    var localizedDisplayName: String {
        ActionCatalog.localizedTitle(for: self) ?? displayName
    }

    var layoutCompatibility: LayoutCompatibility {
        ActionCatalog.layoutCompatibility(for: self) ?? .shared
    }
}
