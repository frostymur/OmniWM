// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM

import AppKit

@MainActor
final class WorkspaceSwipePreview {
    struct Item {
        let handle: WindowHandle
        let token: WindowToken
        let frame: CGRect

        init(handle: WindowHandle, frame: CGRect) {
            self.handle = handle
            token = handle.token
            self.frame = frame
        }
    }

    private(set) var isWarming = false

    var isVisible: Bool {
        false
    }

    init(ownedWindowRegistry: OwnedWindowRegistry) {}

    func prepare(source: [Item], destination: [Item], monitor: Monitor, workingFrame: CGRect? = nil) {}

    func warm(source: [Item], destination: [Item], monitor: Monitor, workingFrame: CGRect? = nil) {}

    func begin(source: [Item], destination: [Item], monitor: Monitor, workingFrame: CGRect? = nil) -> Bool {
        true
    }

    func update(sourceOffset: CGVector, destinationOffset: CGVector) {}

    func stop() {
        isWarming = false
    }
}
