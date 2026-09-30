// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM
// Copyright (C) 2026 Timur Iskakov — https://github.com/frostymur

import CoreGraphics

struct MonitorLayoutFrames {
    let workingFrame: CGRect
    let borderSafeFillFrame: CGRect
    let fullscreenLayoutFrame: CGRect
}

struct NiriInteractionGeometry {
    let workingFrame: CGRect
    let innerGap: CGFloat
    let scale: CGFloat
}
