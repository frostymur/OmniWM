// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM
// Copyright (C) 2026 Timur Iskakov — https://github.com/frostymur

import AppKit
import ApplicationServices
import Dispatch
import Foundation

struct AppAXWindowOperationState: Sendable {
    let windows: ThreadGuardedValue<[Int: AXUIElement]>
    let windowBindingEpoch: LockedGenerationEpoch
    let axObserver: ThreadGuardedValue<AXObserver?>
    let subscribedWindows: ThreadGuardedValue<[Int: AppAXWindowSubscription]>
    let pendingNotificationRemovals: ThreadGuardedValue<[AppAXPendingNotificationRemoval]>
}
