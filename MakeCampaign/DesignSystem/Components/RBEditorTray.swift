import SwiftUI

struct RBEditorTray<Tab: Hashable, Content: View>: View {
    let tabs: [Tab]
    @Binding var selection: Tab
    let label: (Tab) -> String
    let content: (Tab) -> Content

    @Environment(\.rbThemePalette) private var palette

    init(
        _ tabs: [Tab],
        selection: Binding<Tab>,
        label: @escaping (Tab) -> String,
        @ViewBuilder content: @escaping (Tab) -> Content
    ) {
        self.tabs = tabs
        _selection = selection
        self.label = label
        self.content = content
    }

    static func isActive(_ tab: Tab, selection: Tab) -> Bool {
        tab == selection
    }

    var body: some View {
        VStack(spacing: RBSpacing.base) {
            HStack(spacing: RBSpacing.xs) {
                ForEach(tabs, id: \.self) { tab in
                    Button {
                        selection = tab
                    } label: {
                        Text(label(tab))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Self.isActive(tab, selection: selection) ? Color.white : palette.ink)
                            .frame(maxWidth: .infinity, minHeight: 36)
                            .background(Self.isActive(tab, selection: selection) ? palette.accent : Color.clear, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(Self.isActive(tab, selection: selection) ? .isSelected : [])
                }
            }
            .padding(RBSpacing.xs)
            .background(palette.field, in: Capsule())
            content(selection)
        }
        .padding(RBSpacing.base)
        .background(palette.elevatedSurface, in: RoundedRectangle(cornerRadius: RBRadius.large, style: .continuous))
        .shadow(color: RBShadow.editor.color, radius: RBShadow.editor.radius, x: RBShadow.editor.x, y: RBShadow.editor.y)
    }
}

#Preview("Editor tray") {
    RBEditorTray(["Photo", "Data"], selection: .constant("Photo"), label: { $0 }) { tab in
        Text("\(tab) controls")
            .frame(maxWidth: .infinity, minHeight: 80)
    }
    .padding()
    .rbTheme(.light)
}

#Preview("Editor tray dark") {
    RBEditorTray(["Photo", "Data"], selection: .constant("Data"), label: { $0 }) { tab in
        Text("\(tab) controls")
            .frame(maxWidth: .infinity, minHeight: 80)
    }
    .padding()
    .background(RBThemePalette.dark.app)
    .rbTheme(.dark)
}
