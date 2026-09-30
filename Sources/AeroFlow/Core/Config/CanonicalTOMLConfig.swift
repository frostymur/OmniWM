// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM
// Copyright (C) 2026 Timur Iskakov — https://github.com/frostymur

import Foundation

struct CanonicalTOMLConfig: Codable, Equatable {
    var schemaVersion: Int
    var general: General
    var focus: SettingsExport.Focus
    var mouseWarp: SettingsExport.MouseWarp
    var routing: SettingsExport.Routing
    var monitors: Monitors?
    var gaps: SettingsExport.Gaps
    var niri: SettingsExport.Niri
    var dwindle: SettingsExport.Dwindle
    var gestures: SettingsExport.Gestures
    var statusBar: SettingsExport.StatusBar
    var appearance: Appearance
    var hotkeys: [HotkeyBinding]
    var workspaces: [WorkspaceConfiguration]
    var appRules: [AppRule]
    var monitorOrientationOverrides: [MonitorOrientationSettings]
    var monitorNiriOverrides: [MonitorNiriSettings]
    var monitorDwindleOverrides: [MonitorDwindleSettings]
    var monitorGapOverrides: [MonitorGapSettings]

    struct General: Codable, Equatable {
        var hotkeysEnabled: Bool
        var systemHyperTrigger: SystemHyperTrigger
        var hyperKeyModifiers: HyperKeyModifiers
        var defaultLayoutType: LayoutType
        var preventSleepEnabled: Bool
        var updateChecksEnabled: Bool
        var ipcEnabled: Bool
        var animationsEnabled: Bool
        var animationStyle: AnimationStyle
    }

    struct Monitors: Codable, Equatable {
        var ranking: [OutputId]
    }

    struct Appearance: Codable, Equatable {
        var mode: AppearanceMode
        var tabRailAppIcons: Bool
    }
}

extension CanonicalTOMLConfig.General {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        hotkeysEnabled = try container.decode(Bool.self, forKey: .hotkeysEnabled)
        systemHyperTrigger = try container.decode(SystemHyperTrigger.self, forKey: .systemHyperTrigger)
        hyperKeyModifiers = try container.decode(HyperKeyModifiers.self, forKey: .hyperKeyModifiers)
        defaultLayoutType = try container.decode(LayoutType.self, forKey: .defaultLayoutType)
        preventSleepEnabled = try container.decode(Bool.self, forKey: .preventSleepEnabled)
        updateChecksEnabled = try container.decode(Bool.self, forKey: .updateChecksEnabled)
        ipcEnabled = try container.decode(Bool.self, forKey: .ipcEnabled)
        animationsEnabled = try container.decode(Bool.self, forKey: .animationsEnabled)
        animationStyle = try container.decodeIfPresent(AnimationStyle.self, forKey: .animationStyle) ?? .snappy
    }
}

extension CanonicalTOMLConfig.Appearance {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        mode = try container.decode(AppearanceMode.self, forKey: .mode)
        tabRailAppIcons = try container.decodeIfPresent(Bool.self, forKey: .tabRailAppIcons) ?? false
    }
}

extension CanonicalTOMLConfig {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
        general = try container.decode(General.self, forKey: .general)
        KeySymbolMapper.setHyperKeyModifiers(general.hyperKeyModifiers)
        focus = try container.decode(SettingsExport.Focus.self, forKey: .focus)
        mouseWarp = try container.decode(SettingsExport.MouseWarp.self, forKey: .mouseWarp)
        routing = try container.decode(SettingsExport.Routing.self, forKey: .routing)
        monitors = try container.decodeIfPresent(Monitors.self, forKey: .monitors)
        gaps = try container.decode(SettingsExport.Gaps.self, forKey: .gaps)
        niri = try container.decode(SettingsExport.Niri.self, forKey: .niri)
        dwindle = try container.decode(SettingsExport.Dwindle.self, forKey: .dwindle)
        gestures = try container.decode(SettingsExport.Gestures.self, forKey: .gestures)
        statusBar = try container.decode(SettingsExport.StatusBar.self, forKey: .statusBar)
        appearance = try container.decode(Appearance.self, forKey: .appearance)
        let persistedHotkeys = try container.decode([PersistedHotkeyBinding].self, forKey: .hotkeys)
        hotkeys = try HotkeyBindingRegistry.resolve(persistedHotkeys)
        workspaces = try container.decode([WorkspaceConfiguration].self, forKey: .workspaces)
        appRules = try container.decode([AppRule].self, forKey: .appRules)
        monitorOrientationOverrides = try container.decode(
            [MonitorOrientationSettings].self,
            forKey: .monitorOrientationOverrides
        )
        monitorNiriOverrides = try container.decode([MonitorNiriSettings].self, forKey: .monitorNiriOverrides)
        monitorDwindleOverrides = try container.decode([MonitorDwindleSettings].self, forKey: .monitorDwindleOverrides)
        monitorGapOverrides = try container.decode([MonitorGapSettings].self, forKey: .monitorGapOverrides)
    }
}

extension CanonicalTOMLConfig {
    init(export: SettingsExport) {
        schemaVersion = SettingsTOMLCodec.currentSchemaVersion
        general = General(
            hotkeysEnabled: export.hotkeysEnabled,
            systemHyperTrigger: export.systemHyperTrigger,
            hyperKeyModifiers: export.hyperKeyModifiers,
            defaultLayoutType: export.defaultLayoutType,
            preventSleepEnabled: export.preventSleepEnabled,
            updateChecksEnabled: export.updateChecksEnabled,
            ipcEnabled: export.ipcEnabled,
            animationsEnabled: export.animationsEnabled,
            animationStyle: export.animationStyle
        )
        focus = export.focus
        mouseWarp = export.mouseWarp
        routing = export.routing
        monitors = export.monitorRanking.isEmpty ? nil : Monitors(ranking: export.monitorRanking)
        gaps = export.gaps
        niri = export.niri
        dwindle = export.dwindle
        gestures = export.gestures
        statusBar = export.statusBar
        appearance = Appearance(mode: export.appearanceMode, tabRailAppIcons: export.tabRailAppIcons)
        hotkeys = export.hotkeyBindings
        workspaces = export.workspaceConfigurations
        appRules = export.appRules
        monitorOrientationOverrides = export.monitorOrientationSettings
        monitorNiriOverrides = export.monitorNiriSettings
        monitorDwindleOverrides = export.monitorDwindleSettings
        monitorGapOverrides = export.monitorGapSettings
    }

    func toSettingsExport() -> SettingsExport {
        var gestures = gestures
        gestures.windowMoveEnabled = gestures.windowMoveEnabled ?? false
        gestures.windowMoveFingerCount = gestures.windowMoveFingerCount ?? .four
        gestures.windowResizeEnabled = gestures.windowResizeEnabled ?? false
        gestures.windowResizeFingerCount = gestures.windowResizeFingerCount ?? .three
        gestures.windowGestureSensitivity = gestures.windowGestureSensitivity ?? 1.0
        return SettingsExport(
            hotkeysEnabled: general.hotkeysEnabled,
            focus: focus,
            mouseWarp: mouseWarp,
            routing: routing,
            monitorRanking: monitors?.ranking ?? [],
            gaps: gaps,
            niri: niri,
            workspaceConfigurations: workspaces,
            defaultLayoutType: general.defaultLayoutType,
            hotkeyBindings: hotkeys,
            systemHyperTrigger: general.systemHyperTrigger,
            hyperKeyModifiers: general.hyperKeyModifiers,

            appRules: appRules,
            monitorOrientationSettings: monitorOrientationOverrides,
            monitorNiriSettings: monitorNiriOverrides,
            dwindle: dwindle,
            monitorDwindleSettings: monitorDwindleOverrides,
            monitorGapSettings: monitorGapOverrides,
            preventSleepEnabled: general.preventSleepEnabled,
            updateChecksEnabled: general.updateChecksEnabled,
            ipcEnabled: general.ipcEnabled,
            gestures: gestures,
            statusBar: statusBar,
            animationsEnabled: general.animationsEnabled,
            animationStyle: general.animationStyle,
            appearanceMode: appearance.mode,
            tabRailAppIcons: appearance.tabRailAppIcons
        )
    }
}
