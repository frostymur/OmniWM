// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM
// Copyright (C) 2026 Timur Iskakov — https://github.com/frostymur

import AppKit
import Foundation
import AeroFlowIPC

extension WMController {
    func setPreventSleepEnabled(_ enabled: Bool) {
        if enabled {
            SleepPreventionManager.shared.preventSleep()
        } else {
            SleepPreventionManager.shared.allowSleep()
        }
    }

    func clipboardPaletteItems() -> [ClipboardPaletteItem] {
        clipboardHistoryService.paletteItems
    }

    func setClipboardHistoryEnabled(_ enabled: Bool) {
        settings.clipboard.historyEnabled = enabled
        syncClipboardHistoryService()
    }

    func copyClipboardItem(id: UUID, plainText: Bool = false) async -> Bool {
        await clipboardHistoryService.copyItemToPasteboard(id: id, plainText: plainText)
    }

    func clipboardItemPreview(id: UUID) async -> ClipboardPalettePreview? {
        await clipboardHistoryService.preview(id: id)
    }

    func setClipboardItemPinned(_ pinned: Bool, id: UUID) async -> [ClipboardPaletteItem] {
        await clipboardHistoryService.setPinned(pinned, id: id)
    }

    func deleteClipboardItem(id: UUID) async -> [ClipboardPaletteItem] {
        await clipboardHistoryService.deleteItem(id: id)
    }

    func clearClipboardHistory() async throws -> [ClipboardPaletteItem] {
        try await clipboardHistoryService.clearHistory()
    }

    func syncClipboardHistoryService() {
        clipboardHistoryService.updateConfiguration(clipboardHistoryConfiguration())
    }

    func openSponsorsWindow() {
        sponsorsWindowController.show()
    }
}
