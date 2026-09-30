// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM
// Copyright (C) 2026 Timur Iskakov — https://github.com/frostymur

public enum IPCWindowStateCommand: String, CaseIterable, Hashable, Sendable {
    case toggleFloating = "toggle-focused-window-floating"
    case close = "close-focused-window"
}
