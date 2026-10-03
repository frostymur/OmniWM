// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM
// Copyright (C) 2026 Timur Iskakov — https://github.com/frostymur

import AeroFlowIPC
import AppKit
import Foundation

extension WMController {
    func publishWorkspaceDataChanged() {
        if let ipcApplicationBridge {
            Task {
                await ipcApplicationBridge.publishEvent(.windowsChanged)
                await ipcApplicationBridge.publishEvent(.layoutChanged)
            }
        }
    }
}
