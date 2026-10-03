// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM
// Copyright (C) 2026 Timur Iskakov — https://github.com/frostymur

import AeroFlowIPC
import AppKit
import Foundation

extension WMController {
    func applyPersistedSettings(_ settings: SettingsStore, startServices: Bool = true) {
        setAnimationsEnabled(settings.animationsEnabled, persist: false)
        applyCurrentAppearanceMode()

        updateHotkeyBindings(settings.hotkeyBindings)
        setHotkeysEnabled(settings.hotkeysEnabled)

        setGapSize(settings.gaps.size, publishChange: false)

        applyPersistedLayoutSettings(settings)
        applyAnimationStyle(settings.animationStyle, persist: false)
        setTabRailAppIcons(settings.tabRailAppIcons, persist: false)

        updateWorkspaceConfig()
        updateMonitorOrientations()
        updateMonitorNiriSettings()
        updateMonitorDwindleSettings()
        updateMonitorGapSettings()
        updateAppRules()

        setFocusFollowsMouse(settings.focus.followsMouse)
        setMoveMouseToFocusedWindow(settings.focus.moveMouseToFocusedWindow)

        setPreventSleepEnabled(settings.preventSleepEnabled)

        _ = syncMouseWarpPolicy()

        if startServices {
            setEnabled(true)
        }
    }

    func setAnimationsEnabled(_ enabled: Bool, persist: Bool = true) {
        if persist, settings.animationsEnabled != enabled {
            settings.animationsEnabled = enabled
        }

        guard motionPolicy.userAnimationsEnabled != enabled else { return }

        motionPolicy.userAnimationsEnabled = enabled
    }

    func applyAnimationStyle(_ style: AnimationStyle, persist: Bool = true) {
        if persist, settings.animationStyle != style {
            settings.animationStyle = style
        }

        workspaceManager.withEngineMutationScope {
            dwindleEngine?.windowMovementAnimationConfig = style.dwindleConfig
            niriEngine?.windowMovementAnimationConfig = style.niriConfig
        }
    }

    var tabRailStyle: TabRailStyle {
        TabRailStyle(appIcons: settings.tabRailAppIcons)
    }

    func setTabRailAppIcons(_ enabled: Bool, persist: Bool = true) {
        if persist, settings.tabRailAppIcons != enabled {
            settings.tabRailAppIcons = enabled
        }

        let width = TabRailStyle(appIcons: enabled).reservedWidth
        workspaceManager.withEngineMutationScope {
            niriEngine?.updateTabIndicatorWidth(width, motion: motionPolicy.snapshot())
            dwindleEngine?.tabRailWidth = width
        }
        workspaceManager.invalidateAllLayouts()
        layoutRefreshController.requestRelayout(reason: .layoutConfigChanged)
    }

    func applyCurrentAppearanceMode() {
        settings.appearanceMode.apply()
        surfaceReconciler.noteWorldChanged()
    }

    func setGapSize(_ size: Double, publishChange: Bool = true) {
        workspaceManager.setGaps(to: size)
        if publishChange {
            publishDisplayChanged()
        }
    }

    private func applyPersistedLayoutSettings(_ settings: SettingsStore) {
        if niriEngine == nil {
            enableNiriLayout(
                centerFocusedColumn: settings.niri.centerFocusedColumn,
                alwaysCenterSingleColumn: settings.niri.alwaysCenterSingleColumn
            )
        }
        updateNiriConfig(
            visibleContainerCount: settings.niri.visibleContainerCount,
            infiniteLoop: settings.niri.infiniteLoop,
            centerFocusedColumn: settings.niri.centerFocusedColumn,
            alwaysCenterSingleColumn: settings.niri.alwaysCenterSingleColumn,
            singleWindowFit: settings.niri.singleWindowFit,
            containerPrimarySpanPresets: settings.niri.containerPrimarySpanPresets,
            defaultContainerPrimarySpan: settings.niri.defaultContainerPrimarySpan
        )

        if dwindleEngine == nil {
            enableDwindleLayout()
        }
        updateDwindleConfig(
            smartSplit: settings.dwindle.smartSplit,
            defaultSplitRatio: settings.dwindle.defaultSplitRatio,
            splitWidthMultiplier: settings.dwindle.splitWidthMultiplier,
            singleWindowFit: settings.dwindle.singleWindowFit
        )
    }
}
