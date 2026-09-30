// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM
// Copyright (C) 2026 Timur Iskakov — https://github.com/frostymur

import CoreGraphics
import Foundation

extension WorldStore {
    func isAppHidden(pid: pid_t) -> Bool {
        hiddenAppPIDs.contains(pid)
    }
}
