// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM
// Copyright (C) 2026 Timur Iskakov — https://github.com/frostymur

import Carbon
import Foundation

@MainActor
enum HotkeyAdvisoryDetector {
    typealias SystemHotkeyQuery = @MainActor (KeyBinding) -> Bool?

    private struct Advisory {
        let actionID: String
        let command: HotkeyCommand
        let text: String
    }

    private static let knownSystemConflicts: [Advisory] = []

    static func issues(
        currentBindings: [HotkeyBinding],
        defaults: [HotkeyBinding],
        systemHotkeyQuery: SystemHotkeyQuery = liveSystemHotkeyQuery
    ) -> [DiagnosticsIssue] {
        guard !knownSystemConflicts.isEmpty, !currentBindings.isEmpty else { return [] }
        let currentByID = Dictionary(currentBindings.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let defaultsByID = Dictionary(defaults.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        return knownSystemConflicts
            .sorted { $0.command.displayName < $1.command.displayName }
            .compactMap { advisory in
                guard let current = currentByID[advisory.actionID],
                      let defaultBinding = defaultsByID[advisory.actionID],
                      current.binding == defaultBinding.binding,
                      case let .chord(chord) = current.binding,
                      !chord.isUnassigned,
                      systemHotkeyQuery(chord) == true
                else { return nil }
                return DiagnosticsIssue(kind: .hotkeyCoFireAdvisory(
                    actionID: advisory.actionID,
                    command: advisory.command.displayName,
                    chord: chord.displayString,
                    advisory: advisory.text
                ))
            }
    }

    static func liveSystemHotkeyQuery(_ binding: KeyBinding) -> Bool? {
        var unmanagedHotkeys: Unmanaged<CFArray>?
        let status = CopySymbolicHotKeys(&unmanagedHotkeys)
        guard let unmanagedHotkeys else { return nil }
        let hotkeys = unmanagedHotkeys.takeRetainedValue()
        guard status == noErr else { return nil }
        return enabledSystemHotkeyMatches(binding, in: hotkeys)
    }

    static func enabledSystemHotkeyMatches(_ binding: KeyBinding, in hotkeys: CFArray) -> Bool? {
        let keyCodeKey = kHISymbolicHotKeyCode as CFString
        let modifiersKey = kHISymbolicHotKeyModifiers as CFString
        let enabledKey = kHISymbolicHotKeyEnabled as CFString

        for index in 0 ..< CFArrayGetCount(hotkeys) {
            guard let rawEntry = CFArrayGetValueAtIndex(hotkeys, index) else { return nil }
            let entry = Unmanaged<CFTypeRef>.fromOpaque(rawEntry).takeUnretainedValue()
            guard CFGetTypeID(entry) == CFDictionaryGetTypeID() else { return nil }
            let dictionary = unsafeDowncast(entry, to: CFDictionary.self)
            guard let keyCodeValue = value(for: keyCodeKey, in: dictionary),
                  let modifiersValue = value(for: modifiersKey, in: dictionary),
                  let enabledValue = value(for: enabledKey, in: dictionary),
                  let keyCode = uint32(from: keyCodeValue),
                  let modifiers = uint32(from: modifiersValue),
                  CFGetTypeID(enabledValue) == CFBooleanGetTypeID()
            else { return nil }
            let enabled = CFBooleanGetValue(unsafeDowncast(enabledValue, to: CFBoolean.self))
            if enabled, keyCode == binding.keyCode, modifiers == binding.modifiers {
                return true
            }
        }

        return false
    }

    private static func value(for key: CFString, in dictionary: CFDictionary) -> CFTypeRef? {
        guard let rawValue = CFDictionaryGetValue(dictionary, Unmanaged.passUnretained(key).toOpaque()) else {
            return nil
        }
        return Unmanaged<CFTypeRef>.fromOpaque(rawValue).takeUnretainedValue()
    }

    private static func uint32(from value: CFTypeRef) -> UInt32? {
        guard CFGetTypeID(value) == CFNumberGetTypeID() else { return nil }
        var rawValue: Int64 = 0
        guard CFNumberGetValue(unsafeDowncast(value, to: CFNumber.self), .sInt64Type, &rawValue) else { return nil }
        return UInt32(exactly: rawValue)
    }
}
