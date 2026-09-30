// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM
// Copyright (C) 2026 Timur Iskakov — https://github.com/frostymur

import Foundation

enum ApplicationIntakeEvent: Sendable {
    case activated(pid: pid_t)
    case deactivated(pid: pid_t)
    case hidden(pid: pid_t)
    case launched(pid: pid_t)
    case terminated(pid: pid_t, frontmostPID: pid_t?)
    case unhidden(pid: pid_t)
}
