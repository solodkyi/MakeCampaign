import SwiftUI

struct RBFormatOption<Value: Hashable>: View {
    let value: Value
    @Binding var selection: Value
    let title: String
    let detail: String?

    @Environment(\.rbThemePalette) private var palette

    init(
        _ value: Value,
        selection: Binding<Value>,
        title: String,
        detail: String? = nil
    ) {
        self.value = value
        _selection = selection
        self.title = title
        self.detail = detail
    }

    var body: some View {
        Button {
            selection = value
        } label: {
            HStack(spacing: RBSpacing.md) {
                VStack(alignment: .leading, spacing: RBSpacing.xs) {
                    Text(title)
                        .font(RBTypography.cardTitle)
                    if let detail {
                        Text(detail)
                            .font(.system(size: 13))
                            .foregroundStyle(palette.mutedInk)
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: selection == value ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(selection == value ? palette.accent : palette.mutedInk)
            }
            .foregroundStyle(palette.ink)
            .padding(RBSpacing.base)
            .background(selection == value ? palette.accent.opacity(0.10) : palette.surface, in: RoundedRectangle(cornerRadius: RBRadius.control, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: RBRadius.control, style: .continuous)
                    .stroke(selection == value ? palette.accent : palette.border, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selection == value ? .isSelected : [])
    }
}

#Preview("Format option") {
    RBFormatOption("square", selection: .constant("square"), title: "Square", detail: "1080 × 1080")
        .padding()
        .rbTheme(.light)
}

#Preview("Format option dark") {
    RBFormatOption("square", selection: .constant("portrait"), title: "Square", detail: "1080 × 1080")
        .padding()
        .background(RBThemePalette.dark.app)
        .rbTheme(.dark)
}
