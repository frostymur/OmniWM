// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM
// Copyright (C) 2026 Timur Iskakov — https://github.com/frostymur

@testable import AeroFlow
import XCTest

final class TabRailOrderingRegressionTests: XCTestCase {
    func testStableVisibleRailDoesNotReorder() {
        XCTAssertFalse(
            TabRailOrderingPolicy.shouldOrderFront(
                forceOrdering: false,
                wasVisible: true,
                lastActiveWindowId: 41,
                activeWindowId: 41
            )
        )
    }

    func testActiveTabChangeReordersRailAtNormalPanelLevel() {
        XCTAssertTrue(
            TabRailOrderingPolicy.shouldOrderFront(
                forceOrdering: false,
                wasVisible: true,
                lastActiveWindowId: 41,
                activeWindowId: 42
            )
        )
    }

    func testForcedOrHiddenRailReordersWithoutActiveTabChange() {
        XCTAssertTrue(
            TabRailOrderingPolicy.shouldOrderFront(
                forceOrdering: true,
                wasVisible: true,
                lastActiveWindowId: 41,
                activeWindowId: 41
            )
        )
        XCTAssertTrue(
            TabRailOrderingPolicy.shouldOrderFront(
                forceOrdering: false,
                wasVisible: false,
                lastActiveWindowId: 41,
                activeWindowId: 41
            )
        )
    }
}
