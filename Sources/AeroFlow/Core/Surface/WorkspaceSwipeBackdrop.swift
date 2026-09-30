// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM
// Copyright (C) 2026 Timur Iskakov — https://github.com/frostymur

import AppKit

@MainActor
final class WorkspaceSwipeBackdrop {
    private let wallpaperCache: WallpaperCaptureCache

    init(
        wallpaperCache: WallpaperCaptureCache = WallpaperCaptureCache { SkyLight.shared.captureWallpaper(in: $0) }
    ) {
        self.wallpaperCache = wallpaperCache
    }

    func image(for monitor: Monitor) -> CGImage? {
        wallpaperCache.image(
            for: monitor.displayId,
            maxPixelSize: WallpaperCaptureCache.bucketedPixelSize(max(monitor.frame.width, monitor.frame.height)),
            frame: ScreenCoordinateSpace.toWindowServer(rect: monitor.frame)
        )
    }

    func clear() {
        wallpaperCache.clear()
    }
}
