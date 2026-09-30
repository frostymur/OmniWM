// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM
// Copyright (C) 2026 Timur Iskakov — https://github.com/frostymur

import AppKit
import AeroFlow
import SwiftUI

@main
struct AeroFlowApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var bootstrap: AppBootstrapState

    init() {
        let bootstrap = AppBootstrapState()
        _bootstrap = State(wrappedValue: bootstrap)
        AppDelegate.sharedBootstrap = bootstrap
    }

    var body: some Scene {
        Settings {
            SettingsSceneRedirectView(bootstrap: bootstrap)
        }
    }
}
