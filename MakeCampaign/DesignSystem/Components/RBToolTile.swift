import SwiftUI

struct RBToolTile<Icon: View>: View {
    let title: String
    let icon: Icon
    let action: () -> Void

    @Environment(\.rbThemePalette) private var palette

    init(
        _ title: String,
        action: @escaping () -> Void,
        @ViewBuilder icon: () -> Icon
    ) {
        self.title = title
        self.action = action
        self.icon = icon()
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: RBSpacing.sm) {
                icon
                    .frame(width: 28, height: 28)
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .foregroundStyle(palette.ink)
            .frame(maxWidth: .infinity, minHeight: 96)
            .padding(RBSpacing.md)
            .background(palette.surface, in: RoundedRectangle(cornerRadius: RBRadius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: RBRadius.card, style: .continuous)
                    .stroke(palette.border, lineWidth: 1)
            }
            .shadow(color: RBShadow.card.color, radius: RBShadow.card.radius, x: RBShadow.card.x, y: RBShadow.card.y)
        }
        .buttonStyle(.plain)
    }
}

#Preview("Tool tile") {
    RBToolTile("Add photo", action: {}) {
        Image(systemName: "photo")
            .font(.title2)
            .foregroundStyle(RBColor.accent)
    }
    .frame(width: 120)
    .padding()
    .rbTheme(.light)
}

#Preview("Tool tile dark") {
    RBToolTile("Add photo", action: {}) {
        Image(systemName: "photo")
            .font(.title2)
            .foregroundStyle(RBColor.accent)
    }
    .frame(width: 120)
    .padding()
    .background(RBThemePalette.dark.app)
    .rbTheme(.dark)
}
