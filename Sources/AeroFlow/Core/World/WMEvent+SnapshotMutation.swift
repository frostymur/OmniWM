// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM
// Copyright (C) 2026 Timur Iskakov — https://github.com/frostymur

import CoreGraphics
import Foundation

extension WMEvent {
    var mutatesSnapshotAfterPlan: Bool {
        switch self {
        case .windowRemoved:
            true
        case .activeSpaceChanged,
             .appVisibilityInvalidated,
             .floatingGeometryUpdated,
             .floatingStateChanged,
             .focusFallbackRemembered,
             .focusForgotten,
             .focusLeaseChanged,
             .focusRemembered,
             .hiddenApplicationsChanged,
             .windowMinimizedChanged,
             .hiddenStateChanged,
             .interactionMonitorChanged,
             .layoutOperationPerformed,
             .managedFocusCancelled,
             .managedFocusConfirmed,
             .managedFocusRequested,
             .managedReplacementMetadataChanged,
             .manualLayoutOverrideChanged,
             .nativeFocusOwnerChanged,
             .nativeFullscreenPlaceholderSelected,
             .nativeFullscreenTransition,
             .niriPlacementsResolved,
             .dwindlePlacementsResolved,
             .selectionChanged,
             .spaceTopologyChanged,
             .suppressedFocusChanged,
             .systemModalFocusChanged,
             .systemSleep,
             .systemWake,
             .topLevelInventoryObserved,
             .topologyChanged,
             .userCommand,
             .viewportChanged,
             .viewportCommitted,
             .viewportForgotten,
             .visibleWorkspacesChanged,
             .windowAdmissionHintsChanged,
             .windowAdmitted,
             .windowModeChanged,
             .windowRekeyed,
             .workspaceAssigned,
             .workspaceFocusCleared:
            false
        }
    }
}
