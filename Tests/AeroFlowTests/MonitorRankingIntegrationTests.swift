// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM
// Copyright (C) 2026 Timur Iskakov — https://github.com/frostymur

@testable import AeroFlow
import CoreGraphics
import Foundation
import XCTest

@MainActor
final class MonitorRankingIntegrationTests: XCTestCase {
    func testSettingsRoundTripRetainsSameNamedDisplaysAndDefaultsClearRanking() throws {
        let settings = makeSettings()
        let ranking = [
            OutputId(displayId: 960_002, name: "Shared Display"),
            OutputId(displayId: 960_001, name: "Shared Display")
        ]
        settings.monitors.ranking = ranking
        let export = try SettingsTOMLCodec.decode(SettingsTOMLCodec.encode(settings.toExport()))
        settings.monitors.ranking = []
        settings.applyExport(export)

        XCTAssertEqual(settings.monitors.ranking, ranking)
        XCTAssertEqual(settings.toExport().monitorRanking, ranking)

        settings.applyExport(.defaults())

        XCTAssertTrue(settings.monitors.ranking.isEmpty)
        XCTAssertFalse(String(decoding: try SettingsTOMLCodec.encode(settings.toExport()), as: UTF8.self)
            .contains("[monitors]"))
    }

    func testWorkspaceHomesFollowRankingAcrossReorderDisconnectAndReconnect() throws {
        let settings = makeSettings()
        let monitors = makeMonitors()
        settings.monitors.ranking = monitors.reversed().map(OutputId.init(from:))
        settings.workspaces.configurations = [
            WorkspaceConfiguration(name: "1", monitorAssignment: .main, layoutType: .niri),
            WorkspaceConfiguration(name: "2", monitorAssignment: .secondary, layoutType: .niri),
            WorkspaceConfiguration(name: "3", monitorAssignment: .tertiary, layoutType: .niri),
            WorkspaceConfiguration(
                name: "4",
                monitorAssignment: .specificDisplay(OutputId(from: monitors[0])),
                layoutType: .niri
            )
        ]
        let manager = WorkspaceManager(settings: settings)
        manager.applyMonitorConfigurationChange(monitors)
        manager.applySettings()
        let workspaces = try (1 ... 4).map { try XCTUnwrap(manager.workspaceId(named: String($0))) }

        XCTAssertEqual(
            workspaces.map { manager.homeMonitorId(for: $0) },
            [monitors[2].id, monitors[1].id, monitors[0].id, monitors[0].id]
        )

        manager.applyMonitorConfigurationChange(Array(monitors.prefix(2)))

        XCTAssertEqual(
            workspaces.map { manager.homeMonitorId(for: $0) },
            [monitors[1].id, monitors[0].id, nil, monitors[0].id]
        )

        manager.applyMonitorConfigurationChange(monitors)

        XCTAssertEqual(
            workspaces.map { manager.homeMonitorId(for: $0) },
            [monitors[2].id, monitors[1].id, monitors[0].id, monitors[0].id]
        )

        settings.monitors.ranking = monitors.map(OutputId.init(from:))
        manager.applySettings()

        XCTAssertEqual(
            workspaces.map { manager.homeMonitorId(for: $0) },
            [monitors[0].id, monitors[1].id, monitors[2].id, monitors[0].id]
        )
    }

    func testRuntimeMonitorOverrideTakesPrecedenceOverRankedHome() throws {
        let settings = makeSettings()
        let monitors = makeMonitors()
        settings.monitors.ranking = monitors.reversed().map(OutputId.init(from:))
        settings.workspaces.configurations = [
            WorkspaceConfiguration(name: "1", monitorAssignment: .main, layoutType: .niri)
        ]
        let manager = WorkspaceManager(settings: settings)
        manager.applyMonitorConfigurationChange(monitors)
        manager.applySettings()
        let workspace = try XCTUnwrap(manager.workspaceId(named: "1"))

        XCTAssertEqual(manager.moveWorkspaceToMonitor(workspace, to: monitors[0].id, force: true).status, .executed)
        XCTAssertNotNil(manager.descriptor(for: workspace)?.runtimeMonitorOverride)
        XCTAssertEqual(manager.homeMonitorId(for: workspace), monitors[2].id)
        XCTAssertEqual(manager.effectiveMonitor(for: workspace)?.id, monitors[0].id)
    }

    private func makeMonitors() -> [Monitor] {
        (0 ..< 3).map { index in
            let displayId = CGDirectDisplayID(960_001 + index)
            let frame = CGRect(x: index * 600, y: 0, width: 600, height: 400)
            return Monitor(
                id: .init(displayId: displayId),
                displayId: displayId,
                frame: frame,
                visibleFrame: frame,
                hasNotch: false,
                name: "Display \(index)"
            )
        }
    }

    private func makeSettings() -> SettingsStore {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("AeroFlowMonitorRankingTests-\(UUID().uuidString)", isDirectory: true)
        addTeardownBlock {
            try? FileManager.default.removeItem(at: root)
        }
        return SettingsStore(
            persistence: SettingsFilePersistence(
                directory: root.appendingPathComponent("config"),
                startWatching: false,
                deferSaves: false
            ),
            runtimeState: RuntimeStateStore(directory: root.appendingPathComponent("state"), deferSaves: false),
            autosaveEnabled: false
        )
    }
}
