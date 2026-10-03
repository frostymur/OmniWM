// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM
// Copyright (C) 2026 Timur Iskakov — https://github.com/frostymur

import AeroFlowIPC
import Carbon
import Foundation

extension IPCMonitorFocusCommand {
    func actionDisplayName() -> LocalizedStringResource {
        switch self {
        case .previous: LocalizedStringResource(
                "command.monitor.previous", defaultValue: "Focus Previous Monitor", table: "Commands", bundle: .aeroFlow
            )
        case .next: LocalizedStringResource(
                "command.monitor.next", defaultValue: "Focus Next Monitor", table: "Commands", bundle: .aeroFlow
            )
        case .last: LocalizedStringResource(
                "command.monitor.last", defaultValue: "Focus Last Monitor", table: "Commands", bundle: .aeroFlow
            )
        }
    }

    func actionSpec() -> ActionSpec {
        let id: String
        let binding: KeyBinding
        switch self {
        case .previous:
            id = "focusMonitorPrevious"
            binding = .unassigned
        case .next:
            id = "focusMonitorNext"
            binding = KeyBinding(keyCode: UInt32(kVK_Tab), modifiers: UInt32(controlKey | cmdKey))
        case .last:
            id = "focusMonitorLast"
            binding = KeyBinding(keyCode: UInt32(kVK_ANSI_Grave), modifiers: UInt32(controlKey | cmdKey))
        }
        return ActionCatalog.action(
            id: id,
            command: .monitorFocus(self),
            category: .monitor,
            binding: binding
        )
    }
}
