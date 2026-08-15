import SwiftUI

struct RBGlassActionSurface<Content: View>: View {
    let content: Content

    @Environment(\.rbThemePalette) private var palette

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        if #available(iOS 26, *) {
            content
                .foregroundStyle(palette.ink)
                .frame(minWidth: 44, minHeight: 44)
                .padding(.horizontal, RBSpacing.md)
                .background(palette.accent.opacity(0.12), in: Capsule())
                .glassEffect(.regular, in: .capsule)
        } else {
            content
                .foregroundStyle(palette.ink)
                .frame(minWidth: 44, minHeight: 44)
                .padding(.horizontal, RBSpacing.md)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(palette.border.opacity(0.7), lineWidth: 1)
                }
        }
    }
}

#Preview("Glass action surface") {
    RBGlassActionSurface {
        Image(systemName: "ellipsis")
    }
    .padding()
    .rbTheme(.light)
}

#Preview("Glass action surface dark") {
    RBGlassActionSurface {
        Image(systemName: "ellipsis")
    }
    .padding()
    .background(RBThemePalette.dark.app)
    .rbTheme(.dark)
}
