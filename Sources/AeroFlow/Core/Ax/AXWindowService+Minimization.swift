// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM
// Copyright (C) 2026 Timur Iskakov — https://github.com/frostymur

import ApplicationServices
import Foundation

extension AXWindowService {
    static func isMinimized(_ window: AXWindowRef) -> Bool? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            window.element,
            kAXMinimizedAttribute as CFString,
            &value
        )
        return result == .success ? value as? Bool : nil
    }
}
