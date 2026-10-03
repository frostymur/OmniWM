// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM
// Copyright (C) 2026 Timur Iskakov — https://github.com/frostymur

import AeroFlowIPC
import AppKit
import Foundation

extension WMController {
    static func ruleReevaluationLifetimeAuthority(
        existing: ManagedWindowLifetimeAuthority?,
        observedInTopLevelInventory: Bool
    ) -> ManagedWindowLifetimeAuthority {
        if observedInTopLevelInventory {
            return .axTopLevelInventory
        }
        return existing ?? .directLifecycle
    }

    @discardableResult
    func reevaluateWindowRules(
        for targets: Set<WindowRuleReevaluationTarget>,
        context: WindowRuleReevaluationContext = .automatic
    ) async -> WindowRuleReevaluationOutcome {
        guard !targets.isEmpty else { return .none }
        var reevaluation = WindowRuleReevaluation(controller: self, context: context)
        return await reevaluation.run(for: targets)
    }
}
