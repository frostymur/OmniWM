// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM
// Copyright (C) 2026 Timur Iskakov — https://github.com/frostymur

import Foundation
@testable import AeroFlow
import XCTest

final class AppRuleTests: XCTestCase {
    func testNormalizeSingleTitleDropsSubstringWhenBothSet() {
        let rule = AppRule(
            bundleId: "com.test.app",
            titleSubstring: "Main",
            titleRegex: "^Main$",
            layout: .float
        )
        XCTAssertNil(rule.titleSubstring)
        XCTAssertEqual(rule.titleRegex, "^Main$")
    }

    func testNormalizeKeepsLoneTitleMatchers() {
        let substring = AppRule(bundleId: "a", titleSubstring: "Main", layout: .float)
        XCTAssertEqual(substring.titleSubstring, "Main")
        XCTAssertNil(substring.titleRegex)

        let regex = AppRule(bundleId: "a", titleRegex: "^Main$", layout: .float)
        XCTAssertNil(regex.titleSubstring)
        XCTAssertEqual(regex.titleRegex, "^Main$")
    }

    func testNormalizeSingleTitleAppliesOnDecode() throws {
        let json = """
        {"id":"00000000-0000-0000-0000-000000000001","bundleId":"com.test.app",\
        "titleSubstring":"Main","titleRegex":"^Main$","layout":"float"}
        """
        let rule = try JSONDecoder().decode(AppRule.self, from: Data(json.utf8))
        XCTAssertNil(rule.titleSubstring)
        XCTAssertEqual(rule.titleRegex, "^Main$")
    }

    func testHasEffect() {
        XCTAssertFalse(AppRule(bundleId: "com.test.app").hasEffect)
        XCTAssertFalse(AppRule(bundleId: "com.test.app", appNameSubstring: "Test").hasEffect)
        XCTAssertTrue(AppRule(bundleId: "com.test.app", layout: .float).hasEffect)
        XCTAssertTrue(AppRule(bundleId: "com.test.app", assignToWorkspace: "2").hasEffect)
        XCTAssertTrue(AppRule(bundleId: "com.test.app", initialContainerPrimarySpan: 0.05).hasEffect)
        XCTAssertTrue(AppRule(bundleId: "com.test.app", initialContainerPrimarySpan: 1.0).hasEffect)
        XCTAssertTrue(AppRule(bundleId: "com.test.app", minWidth: 400).hasEffect)
        XCTAssertTrue(AppRule(bundleId: "com.test.app", minHeight: 300).hasEffect)
    }

    func testInvalidInitialContainerPrimarySpanDoesNotCountAsEffect() {
        for value in [0.049, 1.001, .nan, .infinity, -.infinity] {
            let rule = AppRule(bundleId: "com.test.app", initialContainerPrimarySpan: value)
            XCTAssertNil(rule.validInitialContainerPrimarySpan)
            XCTAssertFalse(rule.hasEffect)
        }
    }

    func testInitialContainerPrimarySpanRoundTripsThroughTOML() throws {
        var export = SettingsExport.defaults()
        export.appRules = [AppRule(bundleId: "com.test.app", initialContainerPrimarySpan: 0.5)]

        let data = try SettingsTOMLCodec.encode(export)
        let toml = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertTrue(toml.contains("initialContainerPrimarySpan = 0.5"))
        XCTAssertEqual(try SettingsTOMLCodec.decode(data).appRules.first?.initialContainerPrimarySpan, 0.5)
    }

    func testNilInitialContainerPrimarySpanIsOmittedFromJSONAndTOML() throws {
        let rule = AppRule(bundleId: "com.test.app", layout: .float)
        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(rule)) as? [String: Any]
        )
        XCTAssertNil(json["initialContainerPrimarySpan"])

        var export = SettingsExport.defaults()
        export.appRules = [rule]
        let tomlData = try SettingsTOMLCodec.encode(export)
        let toml = try XCTUnwrap(String(data: tomlData, encoding: .utf8))
        XCTAssertFalse(toml.contains("initialContainerPrimarySpan"))
        XCTAssertNil(try SettingsTOMLCodec.decode(tomlData).appRules.first?.initialContainerPrimarySpan)
    }

    func testLegacyInitialColumnWidthTOMLKeyIsIgnoredAndDiagnosed() throws {
        var export = SettingsExport.defaults()
        export.appRules = [
            AppRule(
                bundleId: "com.test.app",
                layout: .float,
                initialContainerPrimarySpan: 0.5
            )
        ]
        let canonical = String(decoding: try SettingsTOMLCodec.encode(export), as: UTF8.self)
        let legacy = Data(
            canonical.replacingOccurrences(
                of: "initialContainerPrimarySpan",
                with: "initialColumnWidth"
            ).utf8
        )

        let decoded = try SettingsTOMLCodec.decode(legacy)

        XCTAssertNil(decoded.appRules.first?.initialContainerPrimarySpan)
        XCTAssertEqual(
            SettingsTOMLCodec.unknownKeyPaths(in: legacy),
            ["appRules[0].initialColumnWidth"]
        )
    }

    @MainActor
    func testAppRulesRevisionChangesOnlyForDistinctRules() {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("AeroFlowRuleRevision-\(UUID().uuidString)", isDirectory: true)
        let settings = SettingsStore(
            persistence: SettingsFilePersistence(
                directory: root.appendingPathComponent("config", isDirectory: true),
                startWatching: false,
                deferSaves: false
            ),
            runtimeState: RuntimeStateStore(
                directory: root.appendingPathComponent("state", isDirectory: true),
                deferSaves: false
            ),
            autosaveEnabled: false
        )
        let baseline = settings.appRulesRevision
        let rules = [AppRule(bundleId: "com.test.app", layout: .float)]

        settings.appRules = rules
        XCTAssertEqual(settings.appRulesRevision, baseline + 1)

        settings.appRules = rules
        XCTAssertEqual(settings.appRulesRevision, baseline + 1)
    }

    @MainActor
    func testIPCProjectionRoundTripsInitialContainerPrimarySpan() {
        let rule = AppRule(bundleId: "com.test.app", initialContainerPrimarySpan: 0.5)
        let definition = IPCRuleProjection.definition(from: rule)
        let projectedRule = IPCRuleProjection.appRule(from: definition, id: rule.id)
        let snapshot = IPCRuleProjection.snapshot(
            from: projectedRule,
            position: 1,
            invalidRegexMessagesByRuleId: [:]
        )

        XCTAssertEqual(definition.initialContainerPrimarySpan, 0.5)
        XCTAssertEqual(projectedRule, rule)
        XCTAssertEqual(snapshot.initialContainerPrimarySpan, 0.5)
        XCTAssertTrue(snapshot.isValid)
    }

    @MainActor
    func testIPCProjectionReportsInvalidInitialContainerPrimarySpan() {
        let rule = AppRule(bundleId: "com.test.app", initialContainerPrimarySpan: 1.001)
        let snapshot = IPCRuleProjection.snapshot(
            from: rule,
            position: 1,
            invalidRegexMessagesByRuleId: [:]
        )

        XCTAssertFalse(snapshot.isValid)
        XCTAssertTrue(snapshot.validationMessages.contains { $0.hasPrefix("Initial container primary span") })
    }

}
