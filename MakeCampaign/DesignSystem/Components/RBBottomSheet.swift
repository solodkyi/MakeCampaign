import SwiftUI

struct RBBottomSheet<Content: View, PrimaryAction: View>: View {
    let title: String
    let content: Content
    let primaryAction: PrimaryAction

    @Environment(\.rbThemePalette) private var palette

    init(
        title: String,
        @ViewBuilder content: () -> Content,
        @ViewBuilder primaryAction: () -> PrimaryAction
    ) {
        self.title = title
        self.content = content()
        self.primaryAction = primaryAction()
    }

    var body: some View {
        VStack(spacing: RBSpacing.lg) {
            Capsule()
                .fill(palette.border)
                .frame(width: 40, height: 5)
                .accessibilityHidden(true)
            Text(title)
                .font(RBTypography.screenTitle)
                .foregroundStyle(palette.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
            content
            primaryAction
        }
        .padding(.horizontal, RBSpacing.lg)
        .padding(.top, RBSpacing.sm)
        .padding(.bottom, RBSpacing.lg)
        .background(palette.elevatedSurface, in: RoundedRectangle(cornerRadius: RBRadius.sheet, style: .continuous))
        .shadow(color: RBShadow.editor.color, radius: RBShadow.editor.radius, x: RBShadow.editor.x, y: RBShadow.editor.y)
    }
}

#Preview("Bottom sheet") {
    RBBottomSheet(title: "Choose format") {
        Text("Select the canvas size for this campaign.")
    } primaryAction: {
        Button("Continue", action: {})
            .buttonStyle(RBPrimaryButtonStyle())
    }
    .padding()
    .rbTheme(.light)
}

#Preview("Bottom sheet dark") {
    RBBottomSheet(title: "Choose format") {
        Text("Select the canvas size for this campaign.")
    } primaryAction: {
        Button("Continue", action: {})
            .buttonStyle(RBPrimaryButtonStyle())
    }
    .padding()
    .background(RBThemePalette.dark.app)
    .rbTheme(.dark)
}
