//
//  RBProgressBar.swift
//  MakeCampaign
//

import SwiftUI

struct RBProgressBar: View {
    let progress: Double

    @Environment(\.rbThemePalette) private var palette

    init(progress: Double) {
        self.progress = progress
    }

    var body: some View {
        GeometryReader { geometry in
            Capsule()
                .fill(palette.border)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(palette.accent)
                        .frame(width: geometry.size.width * Self.clampedProgress(progress))
                }
        }
        .frame(height: 5)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(Self.clampedProgress(progress) * 100)) percent")
    }

    static func clampedProgress(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}

#Preview("Progress bars") {
    VStack(spacing: RBSpacing.base) {
        RBProgressBar(progress: 0.24)
        RBProgressBar(progress: 0.68)
    }
    .padding()
    .rbTheme(.light)
}

#Preview("Progress bar dark") {
    RBProgressBar(progress: 0.68)
        .padding()
        .background(RBThemePalette.dark.app)
        .rbTheme(.dark)
}
