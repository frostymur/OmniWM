// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM
// Copyright (C) 2026 Timur Iskakov — https://github.com/frostymur

import Foundation

struct AdmissionRetryProposal {
    let expectedToken: WindowToken?
    let axRef: AXWindowRef?
    let reason: WindowAdmissionPendingReason
    let trigger: AdmissionRetryTrigger
    let preparedSubscriptionRetainContribution: Int
}
