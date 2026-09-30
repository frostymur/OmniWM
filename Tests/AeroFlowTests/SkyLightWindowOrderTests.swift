// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM
// Copyright (C) 2026 Timur Iskakov — https://github.com/frostymur

@testable import AeroFlow
import XCTest

final class SkyLightWindowOrderTests: XCTestCase {
    func testOrderingModesMatchSkyLightContract() {
        XCTAssertEqual(SkyLightWindowOrder.above.rawValue, 1)
        XCTAssertEqual(SkyLightWindowOrder.out.rawValue, 0)
        XCTAssertEqual(SkyLightWindowOrder.below.rawValue, -1)
    }
}
