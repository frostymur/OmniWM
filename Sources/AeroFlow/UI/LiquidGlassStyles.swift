// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM
// Copyright (C) 2026 Timur Iskakov — https://github.com/frostymur

import SwiftUI

extension View {
    @ViewBuilder
    func omniGlassEffect<S: Shape>(in shape: S, prominent: Bool = false) -> some View {
        if prominent {
            self.background(.regularMaterial, in: shape)
        } else {
            self.background(.regularMaterial, in: shape)
        }
    }
}

struct OmniGlassButtonStyle: ButtonStyle {
    var isProminent: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .omniGlassEffect(in: Capsule(), prominent: isProminent)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

extension ButtonStyle where Self == OmniGlassButtonStyle {
    static var omniGlass: OmniGlassButtonStyle {
        OmniGlassButtonStyle()
    }

    static var omniGlassProminent: OmniGlassButtonStyle {
        OmniGlassButtonStyle(isProminent: true)
    }
}
