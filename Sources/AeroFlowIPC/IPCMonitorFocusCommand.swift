// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM
// Copyright (C) 2026 Timur Iskakov — https://github.com/frostymur

public enum IPCMonitorFocusCommand: String, CaseIterable, Hashable, Sendable {
    case previous = "focus-monitor-previous"
    case next = "focus-monitor-next"
    case last = "focus-monitor-last"
}
