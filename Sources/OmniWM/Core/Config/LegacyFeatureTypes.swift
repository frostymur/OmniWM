// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM

import CoreGraphics
import Foundation

enum WorkspaceBarWindowLevel: String, CaseIterable, Codable, Identifiable, Sendable {
    case normal
    case floating
    case status
    case popup
    case screensaver

    var id: String {
        rawValue
    }
}

enum WorkspaceBarPosition: String, CaseIterable, Codable, Identifiable, Sendable {
    case overlappingMenuBar
    case belowMenuBar

    var id: String {
        rawValue
    }
}

enum WorkspaceBarNotchMode: String, CaseIterable, Codable, Identifiable, Sendable {
    case off
    case moveBelowMenuBar
    case splitActiveLeft
    case splitActiveRight
    case fillLeftOfNotch

    var id: String {
        rawValue
    }
}

enum QuakeTerminalPosition: String, Codable, CaseIterable, Sendable {
    case top
    case bottom
    case left
    case right
    case center
}

enum QuakeTerminalMonitorMode: String, CaseIterable, Codable, Sendable {
    case mouseCursor
    case focusedWindow
    case mainMonitor
}

struct ScratchpadIndex: Hashable, Comparable, Sendable {
    static let range = 1 ... 10

    let rawValue: Int

    init?(_ rawValue: Int) {
        guard Self.range.contains(rawValue) else { return nil }
        self.rawValue = rawValue
    }

    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension ScratchpadIndex: ExpressibleByIntegerLiteral {
    init(integerLiteral value: Int) {
        guard let index = ScratchpadIndex(value) else {
            preconditionFailure("scratchpad slot \(value) is outside \(Self.range)")
        }
        self = index
    }
}

extension ScratchpadIndex: CustomStringConvertible {
    var description: String {
        String(rawValue)
    }
}

struct ScratchpadState: Equatable, Sendable {
    var membersBySlot: [ScratchpadIndex: [WindowToken]] = [:]
    var revealedIndex: ScratchpadIndex?

    init() {}

    mutating func assign(_ token: WindowToken, to index: ScratchpadIndex?) {
        for (slot, members) in membersBySlot where members.contains(token) {
            guard slot != index else { return }
            let remaining = members.filter { $0 != token }
            membersBySlot[slot] = remaining.isEmpty ? nil : remaining
        }
        if let index {
            membersBySlot[index, default: []].append(token)
        }
        if let revealed = revealedIndex, membersBySlot[revealed] == nil {
            revealedIndex = nil
        }
    }

    mutating func rekey(from oldToken: WindowToken, to newToken: WindowToken) {
        guard oldToken != newToken else { return }
        for (slot, members) in membersBySlot {
            guard let position = members.firstIndex(of: oldToken) else { continue }
            membersBySlot[slot]?[position] = newToken
        }
    }

    mutating func reveal(_ index: ScratchpadIndex?) {
        revealedIndex = index.flatMap { membersBySlot[$0] == nil ? nil : $0 }
    }
}

enum OverviewState: Equatable, Sendable {
    case closed
    case open

    var isOpen: Bool {
        self == .open
    }
}

enum OverviewHotkeyDisposition: Equatable, Sendable {
    case inactive
    case handled
    case blocked
}
