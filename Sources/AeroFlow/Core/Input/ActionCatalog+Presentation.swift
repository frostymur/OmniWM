// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM
// Copyright (C) 2026 Timur Iskakov — https://github.com/frostymur

import AeroFlowIPC
import Carbon

extension ActionCatalog {
    static func appendPresentationBindings(_ specs: inout [ActionSpec]) {
        specs.append(contentsOf: [
            action(
                id: "raiseAllFloatingWindows",
                command: .raiseAllFloatingWindows,
                category: .layout,
                binding: KeyBinding(keyCode: UInt32(kVK_ANSI_R), modifiers: UInt32(optionKey | shiftKey)),
                keywords: ["float", "floating", "raise"]
            ),
            action(
                id: "rescueOffscreenWindows",
                command: .rescueOffscreenWindows,
                category: .layout,
                binding: .unassigned,
                keywords: ["rescue", "offscreen", "off-screen"]
            ),
            IPCWindowStateCommand.toggleFloating.actionSpec(),
            IPCWindowStateCommand.close.actionSpec(),
            action(
                id: "toggleWorkspaceLayout",
                command: .workspace(.toggleLayout),
                category: .layout,
                binding: KeyBinding(keyCode: UInt32(kVK_ANSI_L), modifiers: UInt32(optionKey | shiftKey)),
                keywords: ["layout", "niri", "dwindle"]
            )
        ])
    }
}
