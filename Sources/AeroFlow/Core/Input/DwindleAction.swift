// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM
// Copyright (C) 2026 Timur Iskakov — https://github.com/frostymur

import Foundation
import AeroFlowIPC

enum DwindleAction: Equatable, Hashable {
    case moveToRoot
    case toggleSplit
    case swapSplit
    case resizeAlongAxis(DwindleOrientation, Bool)
    case resizeFocusedWindow(Bool)
    case preselect(Direction)
    case preselectClear
}

extension DwindleAction {
    func actionDisplayName() -> LocalizedStringResource {
        switch self {
        case .moveToRoot: LocalizedStringResource(
                "command.dwindle.moveToRoot", defaultValue: "Move to Root", table: "Commands", bundle: .aeroFlow
            )
        case .toggleSplit: LocalizedStringResource(
                "command.dwindle.toggleSplit", defaultValue: "Toggle Split", table: "Commands", bundle: .aeroFlow
            )
        case .swapSplit: LocalizedStringResource(
                "command.dwindle.swapSplit", defaultValue: "Swap Split", table: "Commands", bundle: .aeroFlow
            )
        case .resizeAlongAxis(.horizontal, true): LocalizedStringResource(
                "command.dwindle.growHorizontally", defaultValue: "Grow Horizontally", table: "Commands",
                bundle: .aeroFlow
            )
        case .resizeAlongAxis(.horizontal, false): LocalizedStringResource(
                "command.dwindle.shrinkHorizontally", defaultValue: "Shrink Horizontally", table: "Commands",
                bundle: .aeroFlow
            )
        case .resizeAlongAxis(.vertical, true): LocalizedStringResource(
                "command.dwindle.growVertically", defaultValue: "Grow Vertically", table: "Commands", bundle: .aeroFlow
            )
        case .resizeAlongAxis(.vertical, false): LocalizedStringResource(
                "command.dwindle.shrinkVertically", defaultValue: "Shrink Vertically", table: "Commands",
                bundle: .aeroFlow
            )
        case .resizeFocusedWindow(true): LocalizedStringResource(
                "command.dwindle.growFocusedWindow", defaultValue: "Grow Focused Window", table: "Commands",
                bundle: .aeroFlow
            )
        case .resizeFocusedWindow(false): LocalizedStringResource(
                "command.dwindle.shrinkFocusedWindow", defaultValue: "Shrink Focused Window", table: "Commands",
                bundle: .aeroFlow
            )
        case .preselect(.left): LocalizedStringResource(
                "command.dwindle.preselectLeft", defaultValue: "Preselect Left", table: "Commands", bundle: .aeroFlow
            )
        case .preselect(.right): LocalizedStringResource(
                "command.dwindle.preselectRight", defaultValue: "Preselect Right", table: "Commands", bundle: .aeroFlow
            )
        case .preselect(.up): LocalizedStringResource(
                "command.dwindle.preselectUp", defaultValue: "Preselect Up", table: "Commands", bundle: .aeroFlow
            )
        case .preselect(.down): LocalizedStringResource(
                "command.dwindle.preselectDown", defaultValue: "Preselect Down", table: "Commands", bundle: .aeroFlow
            )
        case .preselectClear: LocalizedStringResource(
                "command.dwindle.clearPreselection", defaultValue: "Clear Preselection", table: "Commands",
                bundle: .aeroFlow
            )
        }
    }

    func ipcCommandName() -> IPCCommandName? {
        switch self {
        case .moveToRoot:
            .dwindle(.moveToRoot)
        case .toggleSplit:
            .dwindle(.toggleSplit)
        case .swapSplit:
            .dwindle(.swapSplit)
        case .resizeAlongAxis:
            .dwindle(.resize)
        case .resizeFocusedWindow:
            .dwindle(.resizeFocused)
        case .preselect:
            .dwindle(.preselect)
        case .preselectClear:
            .dwindle(.preselectClear)
        }
    }

    var compatibility: LayoutCompatibility {
        switch self {
        case .moveToRoot,
             .toggleSplit,
             .swapSplit,
             .resizeAlongAxis,
             .resizeFocusedWindow,
             .preselect,
             .preselectClear:
            .dwindle
        }
    }
}
