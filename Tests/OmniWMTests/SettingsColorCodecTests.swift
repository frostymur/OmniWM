// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM

import Foundation
@testable import OmniWM
import TOML
import XCTest

final class SettingsColorCodecTests: XCTestCase {
    func testCanonicalColorsKeepRGBAObjectsAndTablePaths() throws {
        var export = SettingsExport.defaults()
        export.borders.color.red = 0.1
        export.borders.color.green = 0.2
        export.borders.color.blue = 0.3
        export.borders.color.alpha = 0.4
        export.borders.darkColor = SettingsColor(red: 0.2, green: 0.3, blue: 0.4, alpha: 0.5)
        let expected = [
            "borders.color": ["red": 0.1, "green": 0.2, "blue": 0.3, "alpha": 0.4],
            "borders.darkColor": ["red": 0.2, "green": 0.3, "blue": 0.4, "alpha": 0.5]
        ]
        let canonical = CanonicalTOMLConfig(export: export)
        let json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(canonical))
        let tomlData = try SettingsTOMLCodec.encode(export)
        let toml = try TOMLDecoder().decode([String: TOMLNode].self, from: tomlData)

        for (path, components) in expected {
            var jsonValue = json
            var tomlValue = TOMLNode.table(toml)
            for key in path.split(separator: ".").map(String.init) {
                jsonValue = try XCTUnwrap((jsonValue as? [String: Any])?[key], path)
                guard case let .table(table) = tomlValue else {
                    return XCTFail("Expected TOML table at \(path)")
                }
                tomlValue = try XCTUnwrap(table[key], path)
            }
            XCTAssertEqual(jsonValue as? [String: Double], components, path)
            XCTAssertEqual(tomlValue, .table(components.mapValues(TOMLNode.float)), path)
        }
        XCTAssertEqual(CanonicalTOMLConfig(export: try SettingsTOMLCodec.decode(tomlData)), canonical)
    }
}
