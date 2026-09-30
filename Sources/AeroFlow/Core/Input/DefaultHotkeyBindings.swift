// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM
// Copyright (C) 2026 Timur Iskakov — https://github.com/frostymur

import Carbon

enum DefaultHotkeyBindings {
    static func all() -> [HotkeyBinding] {
        ActionCatalog.defaultHotkeyBindings()
    }
}
