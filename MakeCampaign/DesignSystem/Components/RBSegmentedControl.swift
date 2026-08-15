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
        Picker("Selection", selection: $selection) {
            ForEach(values, id: \.self) { value in
                Text(title(value))
                    .tag(value)
            }
        }
        .pickerStyle(.segmented)
        .font(.system(size: 14, weight: .semibold))
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
