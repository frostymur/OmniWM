// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM
// Copyright (C) 2026 Timur Iskakov — https://github.com/frostymur

import Foundation
import AeroFlowIPC

enum SizingAction: Equatable, Hashable {
    case cycleSizeForward
    case cycleSizeBackward
    case cycleWindowPrimarySpanForward
    case cycleWindowPrimarySpanBackward
    case cycleWindowSecondarySpanForward
    case cycleWindowSecondarySpanBackward
    case toggleContainerFullPrimarySpan
    case expandContainerToAvailablePrimarySpan
    case resetWindowSecondarySpan
    case setContainerPrimarySpan(NiriSizeChange)
    case setWindowPrimarySpan(NiriSizeChange)
    case setWindowSecondarySpan(NiriSizeChange)
    case balanceSizes
}

extension SizingAction {
    func actionDisplayName() -> LocalizedStringResource {
        switch self {
        case .cycleSizeForward: LocalizedStringResource(
                "command.sizing.cycleForward", defaultValue: "Cycle Size Forward", table: "Commands", bundle: .aeroFlow
            )
        case .cycleSizeBackward: LocalizedStringResource(
                "command.sizing.cycleBackward", defaultValue: "Cycle Size Backward", table: "Commands", bundle: .aeroFlow
            )
        case .cycleWindowPrimarySpanForward: LocalizedStringResource(
                "command.sizing.cycleWindowPrimaryForward", defaultValue: "Cycle Window Primary Span Forward",
                table: "Commands", bundle: .aeroFlow
            )
        case .cycleWindowPrimarySpanBackward: LocalizedStringResource(
                "command.sizing.cycleWindowPrimaryBackward", defaultValue: "Cycle Window Primary Span Backward",
                table: "Commands", bundle: .aeroFlow
            )
        case .cycleWindowSecondarySpanForward: LocalizedStringResource(
                "command.sizing.cycleWindowSecondaryForward", defaultValue: "Cycle Window Secondary Span Forward",
                table: "Commands", bundle: .aeroFlow
            )
        case .cycleWindowSecondarySpanBackward: LocalizedStringResource(
                "command.sizing.cycleWindowSecondaryBackward", defaultValue: "Cycle Window Secondary Span Backward",
                table: "Commands", bundle: .aeroFlow
            )
        case .balanceSizes: LocalizedStringResource(
                "command.sizing.balance", defaultValue: "Balance Sizes", table: "Commands", bundle: .aeroFlow
            )
        case .toggleContainerFullPrimarySpan,
             .expandContainerToAvailablePrimarySpan,
             .resetWindowSecondarySpan,
             .setContainerPrimarySpan,
             .setWindowPrimarySpan,
             .setWindowSecondarySpan:
            spanTitle()
        }
    }

    private func spanTitle() -> LocalizedStringResource {
        switch self {
        case .toggleContainerFullPrimarySpan: LocalizedStringResource(
                "command.sizing.toggleContainerFullPrimary", defaultValue: "Toggle Container Full Primary Span",
                table: "Commands", bundle: .aeroFlow
            )
        case .expandContainerToAvailablePrimarySpan: LocalizedStringResource(
                "command.sizing.expandContainerPrimary", defaultValue: "Expand Container to Available Primary Span",
                table: "Commands", bundle: .aeroFlow
            )
        case .resetWindowSecondarySpan: LocalizedStringResource(
                "command.sizing.resetWindowSecondary", defaultValue: "Reset Window Secondary Span", table: "Commands",
                bundle: .aeroFlow
            )
        case let .setContainerPrimarySpan(change): LocalizedStringResource(
                "command.sizing.setContainerPrimary",
                defaultValue: "Set Container Primary Span \(Self.sizeChangeDisplayName(change))", table: "Commands",
                bundle: .aeroFlow
            )
        case let .setWindowPrimarySpan(change): LocalizedStringResource(
                "command.sizing.setWindowPrimary",
                defaultValue: "Set Window Primary Span \(Self.sizeChangeDisplayName(change))", table: "Commands",
                bundle: .aeroFlow
            )
        case let .setWindowSecondarySpan(change): LocalizedStringResource(
                "command.sizing.setWindowSecondary",
                defaultValue: "Set Window Secondary Span \(Self.sizeChangeDisplayName(change))", table: "Commands",
                bundle: .aeroFlow
            )
        case .cycleSizeForward,
             .cycleSizeBackward,
             .cycleWindowPrimarySpanForward,
             .cycleWindowPrimarySpanBackward,
             .cycleWindowSecondarySpanForward,
             .cycleWindowSecondarySpanBackward,
             .balanceSizes:
            actionDisplayName()
        }
    }

    func ipcCommandName() -> IPCCommandName? {
        switch self {
        case .cycleSizeForward:
            .sizing(.cycleSizeForward)
        case .cycleSizeBackward:
            .sizing(.cycleSizeBackward)
        case .cycleWindowPrimarySpanForward:
            .sizing(.cycleWindowPrimarySpanForward)
        case .cycleWindowPrimarySpanBackward:
            .sizing(.cycleWindowPrimarySpanBackward)
        case .cycleWindowSecondarySpanForward:
            .sizing(.cycleWindowSecondarySpanForward)
        case .cycleWindowSecondarySpanBackward:
            .sizing(.cycleWindowSecondarySpanBackward)
        case .toggleContainerFullPrimarySpan:
            .sizing(.toggleContainerFullPrimarySpan)
        case .expandContainerToAvailablePrimarySpan:
            .sizing(.expandContainerToAvailablePrimarySpan)
        case .resetWindowSecondarySpan:
            .sizing(.resetWindowSecondarySpan)
        case .setContainerPrimarySpan:
            .sizing(.setContainerPrimarySpan)
        case .setWindowPrimarySpan:
            .sizing(.setWindowPrimarySpan)
        case .setWindowSecondarySpan:
            .sizing(.setWindowSecondarySpan)
        case .balanceSizes:
            .dwindle(.balanceSizes)
        }
    }

    var compatibility: LayoutCompatibility {
        switch self {
        case .cycleSizeForward,
             .cycleSizeBackward,
             .balanceSizes:
            .shared
        case .cycleWindowPrimarySpanForward,
             .cycleWindowPrimarySpanBackward,
             .cycleWindowSecondarySpanForward,
             .cycleWindowSecondarySpanBackward,
             .toggleContainerFullPrimarySpan,
             .expandContainerToAvailablePrimarySpan,
             .resetWindowSecondarySpan,
             .setContainerPrimarySpan,
             .setWindowPrimarySpan,
             .setWindowSecondarySpan:
            .niri
        }
    }

    private static func sizeChangeDisplayName(_ change: NiriSizeChange) -> String {
        switch change {
        case let .setFixed(value):
            "Fixed \(Int(value))px"
        case let .setProportion(value):
            "\(Int(value))%"
        case let .adjustFixed(value):
            "\(value >= 0 ? "+" : "")\(Int(value))px"
        case let .adjustProportion(value):
            "\(value >= 0 ? "+" : "")\(Int(value))%"
        }
    }
}
