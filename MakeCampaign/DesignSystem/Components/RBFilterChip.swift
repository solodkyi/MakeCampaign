//
//  RBFilterChip.swift
//  MakeCampaign
//

import SwiftUI

struct RBFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.rbThemePalette) private var palette

    init(_ title: String, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isSelected ? Color.white : palette.ink)
                .padding(.horizontal, RBSpacing.base)
                .frame(height: 36)
                .background(isSelected ? palette.accent : palette.field)
                .overlay {
                    Capsule()
                        .stroke(isSelected ? .clear : palette.border, lineWidth: 1)
                }
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview("Filter chips") {
    HStack {
        RBFilterChip("Active", isSelected: true) {}
        RBFilterChip("Archived", isSelected: false) {}
    }
    .padding()
    .rbTheme(.light)
}

#Preview("Filter chips dark") {
    HStack {
        RBFilterChip("Active", isSelected: true) {}
        RBFilterChip("Archived", isSelected: false) {}
    }
    .padding()
    .background(RBThemePalette.dark.app)
    .rbTheme(.dark)
}
