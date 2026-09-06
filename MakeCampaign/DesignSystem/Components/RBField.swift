//
//  RBField.swift
//  MakeCampaign
//

import SwiftUI

struct RBFieldLabel: View {
    let title: String
    let message: String?

    @Environment(\.rbThemePalette) private var palette

    init(_ title: String, message: String? = nil) {
        self.title = title
        self.message = message
    }

    var body: some View {
        VStack(alignment: .leading, spacing: RBSpacing.xs) {
            Text(title)
                .font(RBTypography.microLabel)
                .foregroundStyle(palette.mutedInk)
            if let message {
                Text(message)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(palette.destructive)
            }
        }
    }
}

struct RBTextFieldStyle: TextFieldStyle {
    @Environment(\.rbThemePalette) private var palette

    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(size: 16))
            .foregroundStyle(palette.ink)
            .padding(.horizontal, RBSpacing.base)
            .frame(height: 48)
            .background(palette.field)
            .overlay {
                RoundedRectangle(cornerRadius: RBRadius.field, style: .continuous)
                    .stroke(palette.border, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: RBRadius.field, style: .continuous))
    }
}

#Preview("Field") {
    VStack(alignment: .leading, spacing: RBSpacing.sm) {
        RBFieldLabel("Campaign name")
        TextField("Summer fundraiser", text: .constant(""))
            .textFieldStyle(RBTextFieldStyle())
        RBFieldLabel("Target", message: "Enter a valid amount")
    }
    .padding()
    .rbTheme(.light)
}

#Preview("Field dark") {
    VStack(alignment: .leading, spacing: RBSpacing.sm) {
        RBFieldLabel("Campaign name")
        TextField("Summer fundraiser", text: .constant(""))
            .textFieldStyle(RBTextFieldStyle())
    }
    .padding()
    .background(RBThemePalette.dark.app)
    .rbTheme(.dark)
}
