// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM
// Copyright (C) 2026 Timur Iskakov — https://github.com/frostymur

import AeroFlowIPC
import Foundation

enum FocusNavigationAction: Equatable, Hashable {
    case previous
    case downOrLeft
    case upOrRight
    case windowInColumn(Int)
    case windowTop
    case windowBottom
    case windowDownOrTop
    case windowUpOrBottom
    case windowOrWorkspaceDown
    case windowOrWorkspaceUp
    case columnFirst
    case columnLast
    case column(Int)
    case centerColumn
    case centerVisibleColumns
}

extension FocusNavigationAction {
    func actionDisplayName() -> LocalizedStringResource {
        switch self {
        case .previous: LocalizedStringResource(
                "command.focus.previous", defaultValue: "Focus Previous Window", table: "Commands", bundle: .aeroFlow
            )
        case .downOrLeft: LocalizedStringResource(
                "command.focus.traverseBackward", defaultValue: "Traverse Backward", table: "Commands",
                bundle: .aeroFlow
            )
        case .upOrRight: LocalizedStringResource(
                "command.focus.traverseForward", defaultValue: "Traverse Forward", table: "Commands", bundle: .aeroFlow
            )
        case .columnFirst: LocalizedStringResource(
                "command.focus.columnFirst", defaultValue: "Focus First Column", table: "Commands", bundle: .aeroFlow
            )
        case .columnLast: LocalizedStringResource(
                "command.focus.columnLast", defaultValue: "Focus Last Column", table: "Commands", bundle: .aeroFlow
            )
        case let .column(idx): LocalizedStringResource(
                "command.focus.column", defaultValue: "Focus Column \(idx + 1)", table: "Commands", bundle: .aeroFlow
            )
        case .centerColumn: LocalizedStringResource(
                "command.focus.centerColumn", defaultValue: "Center Column", table: "Commands", bundle: .aeroFlow
            )
        case .centerVisibleColumns: LocalizedStringResource(
                "command.focus.centerVisibleColumns", defaultValue: "Center Visible Columns", table: "Commands",
                bundle: .aeroFlow
            )
        case .windowInColumn,
             .windowTop,
             .windowBottom,
             .windowDownOrTop,
             .windowUpOrBottom,
             .windowOrWorkspaceDown,
             .windowOrWorkspaceUp:
            windowTitle()
        }
    }

    private func windowTitle() -> LocalizedStringResource {
        switch self {
        case let .windowInColumn(idx): LocalizedStringResource(
                "command.focus.windowInColumn", defaultValue: "Focus Window \(idx) in Column", table: "Commands",
                bundle: .aeroFlow
            )
        case .windowTop: LocalizedStringResource(
                "command.focus.windowTop", defaultValue: "Focus Top Window", table: "Commands", bundle: .aeroFlow
            )
        case .windowBottom: LocalizedStringResource(
                "command.focus.windowBottom", defaultValue: "Focus Bottom Window", table: "Commands", bundle: .aeroFlow
            )
        case .windowDownOrTop: LocalizedStringResource(
                "command.focus.windowDownOrTop", defaultValue: "Focus Down or Top", table: "Commands", bundle: .aeroFlow
            )
        case .windowUpOrBottom: LocalizedStringResource(
                "command.focus.windowUpOrBottom", defaultValue: "Focus Up or Bottom", table: "Commands",
                bundle: .aeroFlow
            )
        case .windowOrWorkspaceDown: LocalizedStringResource(
                "command.focus.windowOrWorkspaceDown", defaultValue: "Focus Window or Workspace Down",
                table: "Commands", bundle: .aeroFlow
            )
        case .windowOrWorkspaceUp: LocalizedStringResource(
                "command.focus.windowOrWorkspaceUp", defaultValue: "Focus Window or Workspace Up", table: "Commands",
                bundle: .aeroFlow
            )
        case .previous,
             .downOrLeft,
             .upOrRight,
             .columnFirst,
             .columnLast,
             .column,
             .centerColumn,
             .centerVisibleColumns:
            actionDisplayName()
        }
    }

    func ipcCommandName() -> IPCCommandName? {
        switch self {
        case .previous:
            .focus(.previous)
        case .downOrLeft:
            .focus(.downOrLeft)
        case .upOrRight:
            .focus(.upOrRight)
        case .windowInColumn:
            .focus(.windowInColumn)
        case .windowTop:
            .focus(.windowTop)
        case .windowBottom:
            .focus(.windowBottom)
        case .windowDownOrTop:
            .focus(.windowDownOrTop)
        case .windowUpOrBottom:
            .focus(.windowUpOrBottom)
        case .windowOrWorkspaceDown:
            .focus(.windowOrWorkspaceDown)
        case .windowOrWorkspaceUp:
            .focus(.windowOrWorkspaceUp)
        case .column:
            .focus(.column)
        case .columnFirst:
            .focus(.columnFirst)
        case .columnLast:
            .focus(.columnLast)
        case .centerColumn:
            .focus(.centerColumn)
        case .centerVisibleColumns:
            .focus(.centerVisibleColumns)
        }
    }

    var compatibility: LayoutCompatibility {
        switch self {
        case .previous,
             .windowDownOrTop,
             .windowUpOrBottom:
            .shared
        case .downOrLeft,
             .upOrRight,
             .windowInColumn,
             .windowTop,
             .windowBottom,
             .windowOrWorkspaceDown,
             .windowOrWorkspaceUp,
             .columnFirst,
             .columnLast,
             .column,
             .centerColumn,
             .centerVisibleColumns:
            .niri
        }
    }
}
