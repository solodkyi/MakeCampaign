//
//  RBSegmentedControl.swift
//  MakeCampaign
//

import SwiftUI

struct RBSegmentedControl<Value: Hashable>: View {
    let values: [Value]
    @Binding var selection: Value
    let title: (Value) -> String

    @Environment(\.rbThemePalette) private var palette

    init(
        _ values: [Value],
        selection: Binding<Value>,
        title: @escaping (Value) -> String
    ) {
        self.values = values
        _selection = selection
        self.title = title
    }

    var body: some View {
        HStack(spacing: RBSpacing.xs) {
            ForEach(values, id: \.self) { value in
                let isSelected = value == selection
                Button {
                    selection = value
                } label: {
                    Text(title(value))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isSelected ? palette.ink : palette.mutedInk)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(isSelected ? palette.surface : .clear)
                        .clipShape(RoundedRectangle(cornerRadius: RBRadius.compact, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(RBSpacing.xs)
        .background(palette.field)
        .clipShape(RoundedRectangle(cornerRadius: RBRadius.control, style: .continuous))
    }
}

#Preview("Segmented control") {
    RBSegmentedControl(["Week", "Month", "Year"], selection: .constant("Month"), title: { $0 })
        .padding()
        .rbTheme(.light)
}

#Preview("Segmented control dark") {
    RBSegmentedControl(["Week", "Month", "Year"], selection: .constant("Month"), title: { $0 })
        .padding()
        .background(RBThemePalette.dark.app)
        .rbTheme(.dark)
}
