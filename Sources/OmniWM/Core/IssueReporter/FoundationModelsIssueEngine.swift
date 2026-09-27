// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM

import Foundation
#if canImport(FoundationModels)
    import FoundationModels
#endif

@available(macOS 15.1, *)
@MainActor
final class FoundationModelsIssueEngine: IssueRewriting {
    var availability: IssueAIAvailability {
        .modelNotReady
    }

    func rewrite(_ freeform: String, hotkeyContext: String) async throws -> RewrittenIssue {
        throw IssueReportError.generationFailed("Not supported")
    }
}
