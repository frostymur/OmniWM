// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM
// Copyright (C) 2026 Timur Iskakov — https://github.com/frostymur

import AppKit
import Foundation
import AeroFlowIPC

extension WMController {
    func innerGap(for monitor: Monitor) -> CGFloat {
        innerGap(for: monitor, scale: backingScaleFactor(for: monitor))
    }

    func innerGap(for monitor: Monitor, scale: CGFloat) -> CGFloat {
        return settings.gaps.settings(for: monitor)?.innerGap == nil
            ? CGFloat(workspaceManager.gaps)
            : settings.gaps.resolved(for: monitor).innerGap
    }

    func innerGap(for workspaceId: WorkspaceDescriptor.ID) -> CGFloat {
        guard let monitor = workspaceManager.monitor(for: workspaceId) else {
            return CGFloat(workspaceManager.gaps)
        }
        return innerGap(for: monitor)
    }

    func resolvedDwindleSettings(for monitor: Monitor) -> ResolvedDwindleSettings {
        resolvedDwindleSettings(for: monitor, scale: backingScaleFactor(for: monitor))
    }

    func resolvedDwindleSettings(for monitor: Monitor, scale: CGFloat) -> ResolvedDwindleSettings {
        let resolved = settings.dwindle.resolved(for: monitor)
        return ResolvedDwindleSettings(
            smartSplit: resolved.smartSplit,
            defaultSplitRatio: resolved.defaultSplitRatio,
            splitWidthMultiplier: resolved.splitWidthMultiplier,
            singleWindowFit: resolved.singleWindowFit,
            useGlobalGaps: resolved.useGlobalGaps,
            innerGap: resolved.innerGap
        )
    }

    func layoutFrames(
        for monitor: Monitor,
        scale: CGFloat
    ) -> MonitorLayoutFrames {
        let reservedTopInset: CGFloat = 0
        let gaps = settings.gaps.resolved(for: monitor)
        let menuBarInset = max(0, monitor.frame.maxY - monitor.visibleFrame.maxY)
        let normalizedTop = normalizedTopStrut(
            top: gaps.outerGapTop,
            menuBarInset: menuBarInset,
            reservedTopInset: reservedTopInset
        )
        let rawStruts = Struts(
            left: gaps.outerGapLeft,
            right: gaps.outerGapRight,
            top: normalizedTop,
            bottom: gaps.outerGapBottom
        )
        let workingFrame = computeWorkingArea(
            parentArea: monitor.visibleFrame,
            scale: scale,
            struts: rawStruts
        )
        let fullscreenLayoutFrame: CGRect
        let borderSafeFillFrame: CGRect
        if gaps.fullscreenUsesOuterGaps {
            fullscreenLayoutFrame = workingFrame
            borderSafeFillFrame = workingFrame
        } else {
            (fullscreenLayoutFrame, borderSafeFillFrame) = ungappedFullscreenFrames(
                for: monitor, scale: scale, reservedTopInset: reservedTopInset
            )
        }
        return MonitorLayoutFrames(
            workingFrame: workingFrame,
            borderSafeFillFrame: borderSafeFillFrame,
            fullscreenLayoutFrame: fullscreenLayoutFrame
        )
    }

    func niriInteractionGeometry(
        for monitor: Monitor
    ) -> NiriInteractionGeometry {
        niriInteractionGeometry(for: monitor, scale: backingScaleFactor(for: monitor))
    }

    func niriInteractionGeometry(
        for monitor: Monitor,
        scale: CGFloat
    ) -> NiriInteractionGeometry {
        let workingFrame = layoutFrames(for: monitor, scale: scale).workingFrame
        return NiriInteractionGeometry(
            workingFrame: workingFrame,
            innerGap: innerGap(for: monitor, scale: scale),
            scale: scale
        )
    }

    func insetWorkingFrame(for monitor: Monitor) -> CGRect {
        let scale = backingScaleFactor(for: monitor)
        return layoutFrames(for: monitor, scale: scale).workingFrame
    }

    func fullscreenLayoutFrame(for monitor: Monitor) -> CGRect {
        let scale = backingScaleFactor(for: monitor)
        return layoutFrames(for: monitor, scale: scale).fullscreenLayoutFrame
    }

    func borderSafeFillFrame(for monitor: Monitor) -> CGRect {
        let scale = backingScaleFactor(for: monitor)
        return layoutFrames(for: monitor, scale: scale).borderSafeFillFrame
    }

    func backingScaleFactor(for monitor: Monitor) -> CGFloat {
        NSScreen.screens.first(where: { $0.displayId == monitor.displayId })?.backingScaleFactor ?? 2.0
    }

    private func ungappedFullscreenFrames(
        for monitor: Monitor,
        scale: CGFloat,
        reservedTopInset: CGFloat
    ) -> (layout: CGRect, borderSafe: CGRect) {
        let layout = computeWorkingArea(
            parentArea: monitor.visibleFrame,
            scale: scale,
            struts: Struts(top: reservedTopInset)
        )
        return (layout, layout)
    }
}
