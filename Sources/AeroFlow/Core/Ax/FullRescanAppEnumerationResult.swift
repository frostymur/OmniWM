// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM
// Copyright (C) 2026 Timur Iskakov — https://github.com/frostymur

import AppKit
import ApplicationServices
import CoreGraphics
import Foundation

struct FullRescanAppEnumerationResult: Sendable {
    let pid: pid_t
    let route: FullRescanEnumerationRoute
    let windows: [AXEnumeratedWindow]
    let failed: Bool
    let callbackGeneration: UInt64?
}

extension FullRescanAppEnumerationResult {
    static func failed(
        pid: pid_t,
        route: FullRescanEnumerationRoute,
        callbackGeneration: UInt64?
    ) -> Self {
        .init(pid: pid, route: route, windows: [], failed: true, callbackGeneration: callbackGeneration)
    }
}
