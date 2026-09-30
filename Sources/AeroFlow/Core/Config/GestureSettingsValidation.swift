// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM
// Copyright (C) 2026 Timur Iskakov — https://github.com/frostymur

import Foundation

struct TrackpadGestureConflict: Error, Equatable, LocalizedError {
    let fingerCount: Int
    let gesture: TrackpadGestureMode
    let otherGesture: TrackpadGestureMode

    var errorDescription: String? {
        let first = Self.name(for: gesture)
        let second = Self.name(for: otherGesture)
        return String(
            localized: "\(first) and \(second) both use a \(fingerCount)-finger gesture. Choose different fingers or disable one gesture.",
            comment: "Trackpad gesture conflict; the placeholders are gesture names"
        )
    }

    private static func name(for gesture: TrackpadGestureMode) -> String {
        switch gesture {
        case .columnScroll: String(localized: "Niri column scrolling", comment: "Trackpad gesture name")
        case .workspaceSwitch: String(localized: "workspace switching", comment: "Trackpad gesture name")
        case .windowMove: String(localized: "window moving", comment: "Trackpad gesture name")
        case .windowResize: String(localized: "window resizing", comment: "Trackpad gesture name")
        }
    }
}

enum GestureSettingsValidation {
    static func validate(_ export: SettingsExport, monitorProvider: () -> [Monitor]) throws {
        guard export.gestures.windowMoveEnabled == true || export.gestures.windowResizeEnabled == true
        else { return }
        if let conflict = conflict(
            gestures: export.gestures,
            orientationOverrides: export.monitorOrientationSettings,
            monitors: []
        ) {
            throw conflict
        }
    }

    static func conflict(
        gestures: SettingsExport.Gestures,
        orientationOverrides: [MonitorOrientationSettings],
        monitors: [Monitor]
    ) -> TrackpadGestureConflict? {
        let config = TrackpadGestureIntent.Config(
            columnScrollEnabled: gestures.scrollEnabled,
            columnScrollFingerCount: gestures.fingerCount.rawValue,
            workspaceSwipeEnabled: gestures.workspaceSwipeEnabled,
            workspaceSwipeFingerCount: gestures.workspaceSwipeFingerCount.rawValue,
            workspaceSwipeAxis: gestures.workspaceSwipeAxis,
            windowMoveEnabled: gestures.windowMoveEnabled ?? false,
            windowMoveFingerCount: (gestures.windowMoveFingerCount ?? .four).rawValue,
            windowResizeEnabled: gestures.windowResizeEnabled ?? false,
            windowResizeFingerCount: (gestures.windowResizeFingerCount ?? .three).rawValue
        )
        for (enabled, mode, fingers) in [
            (config.windowMoveEnabled, TrackpadGestureMode.windowMove, config.windowMoveFingerCount),
            (config.windowResizeEnabled, .windowResize, config.windowResizeFingerCount)
        ] where enabled {
            if let other = TrackpadGestureIntent.windowGestureConflict(config, mode: mode) {
                return TrackpadGestureConflict(fingerCount: fingers, gesture: mode, otherGesture: other)
            }
        }
        return nil
    }
}
