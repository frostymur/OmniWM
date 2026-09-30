// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM
// Copyright (C) 2026 Timur Iskakov — https://github.com/frostymur

import AppKit
import AeroFlow

@main
@MainActor
enum AeroFlowApp {
    static func main() {
        let bootstrap = AppBootstrapState()
        AppDelegate.sharedBootstrap = bootstrap
        let app = NSApplication.shared
        app.delegate = AppDelegate()
        app.run()
    }
}
