// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM
// Copyright (C) 2026 Timur Iskakov — https://github.com/frostymur

import Foundation
@testable import AeroFlow
import XCTest

@MainActor
final class StatusBarOwnerLifetimeTests: XCTestCase {
    func testRetainedReadOnlySectionOutlivesStoreWithoutRetainingIt() {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        weak var releasedStore: SettingsStore?
        let section: StatusBarSettings
        do {
            let settings = SettingsStore(
                persistence: SettingsFilePersistence(directory: directory, startWatching: false, deferSaves: false),
                runtimeState: RuntimeStateStore(directory: directory, deferSaves: false),
                autosaveEnabled: false
            )
            settings.statusBar.showWorkspaceName = true
            releasedStore = settings
            section = settings.statusBar
        }

        XCTAssertNil(releasedStore)
        XCTAssertTrue(section.showWorkspaceName)
        XCTAssertTrue(section.export().showWorkspaceName)
    }
}
