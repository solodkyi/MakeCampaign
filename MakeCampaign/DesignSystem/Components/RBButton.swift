//
//  RBButton.swift
//  MakeCampaign
//

import SwiftUI

struct RBPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.rbThemePalette) private var palette

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(RBTypography.cardTitle)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(isEnabled ? palette.accent : palette.accent.opacity(0.45))
            .clipShape(RoundedRectangle(cornerRadius: RBRadius.control, style: .continuous))
            .opacity(configuration.isPressed ? 0.86 : 1)
    }
}

#Preview("Primary button") {
    VStack(spacing: RBSpacing.md) {
        Button("Create campaign") {}
            .buttonStyle(RBPrimaryButtonStyle())
        Button("Unavailable") {}
            .buttonStyle(RBPrimaryButtonStyle())
            .disabled(true)
    }
    .padding()
    .rbTheme(.light)
}

#Preview("Primary button dark") {
    Button("Create campaign") {}
        .buttonStyle(RBPrimaryButtonStyle())
        .padding()
        .background(RBThemePalette.dark.app)
        .rbTheme(.dark)
}
