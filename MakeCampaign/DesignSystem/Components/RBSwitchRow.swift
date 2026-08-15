//
//  RBSwitchRow.swift
//  MakeCampaign
//

import SwiftUI

struct RBSwitchRow: View {
    let title: String
    @Binding var isOn: Bool

    @Environment(\.rbThemePalette) private var palette

    init(_ title: String, isOn: Binding<Bool>) {
        self.title = title
        _isOn = isOn
    }

    var body: some View {
        Toggle(title, isOn: $isOn)
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(palette.ink)
            .toggleStyle(RBSwitchToggleStyle())
    }
}

private struct RBSwitchToggleStyle: ToggleStyle {
    @Environment(\.rbThemePalette) private var palette

    func makeBody(configuration: Configuration) -> some View {
        let stateLabel = configuration.isOn ? "On" : "Off"

        HStack {
            configuration.label
            Spacer(minLength: RBSpacing.base)
            Button {
                configuration.isOn.toggle()
            } label: {
                Capsule()
                    .fill(configuration.isOn ? palette.accent : palette.border)
                    .frame(width: 51, height: 31)
                    .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                        Circle()
                            .fill(palette.surface)
                            .padding(3)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(stateLabel)
        }
    }
}

#Preview("Switch row") {
    RBSwitchRow("Allow notifications", isOn: .constant(true))
        .padding()
        .rbTheme(.light)
}

#Preview("Switch row dark") {
    RBSwitchRow("Allow notifications", isOn: .constant(false))
        .padding()
        .background(RBThemePalette.dark.app)
        .rbTheme(.dark)
}
