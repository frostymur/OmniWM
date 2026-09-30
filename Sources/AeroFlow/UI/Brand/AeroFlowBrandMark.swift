// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM
// Copyright (C) 2026 Timur Iskakov — https://github.com/frostymur

import AppKit

@MainActor
enum AeroFlowBrandMark {
    private static let statusTemplateSource = resourceImage(named: "AeroFlowStatusTemplate", isTemplate: true)
    private static var statusTemplates: [CGFloat: NSImage] = [:]

    static func statusItemImage(pointSize: CGFloat) -> NSImage {
        let template: NSImage
        if let cached = statusTemplates[pointSize] {
            template = cached
        } else {
            guard let image = statusTemplateSource.copy() as? NSImage else {
                fatalError("Unable to copy bundled brand resource AeroFlowStatusTemplate.pdf")
            }
            image.size = NSSize(width: pointSize, height: pointSize)
            image.isTemplate = true
            statusTemplates[pointSize] = image
            template = image
        }
        guard let image = template.copy() as? NSImage else {
            fatalError("Unable to copy bundled brand resource AeroFlowStatusTemplate.pdf")
        }
        image.isTemplate = true
        return image
    }

    private static func resourceImage(named name: String, isTemplate: Bool) -> NSImage {
        guard let url = Bundle.module.url(forResource: name, withExtension: "pdf"),
              let image = NSImage(contentsOf: url),
              image.isValid,
              image.size.width > 0,
              image.size.height > 0
        else {
            fatalError("Missing bundled brand resource \(name).pdf")
        }
        image.isTemplate = isTemplate
        return image
    }
}
