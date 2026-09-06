import SwiftUI

struct RBCampaignCard<Thumbnail: View, Metadata: View>: View {
    let title: String
    let thumbnail: Thumbnail
    let metadata: Metadata

    @Environment(\.rbThemePalette) private var palette

    init(
        title: String,
        @ViewBuilder thumbnail: () -> Thumbnail,
        @ViewBuilder metadata: () -> Metadata
    ) {
        self.title = title
        self.thumbnail = thumbnail()
        self.metadata = metadata()
    }

    var body: some View {
        HStack(spacing: RBSpacing.base) {
            thumbnail
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: RBRadius.field, style: .continuous))
            VStack(alignment: .leading, spacing: RBSpacing.sm) {
                Text(title)
                    .font(RBTypography.cardTitle)
                    .foregroundStyle(palette.ink)
                    .lineLimit(2)
                metadata
            }
            Spacer(minLength: 0)
        }
        .padding(RBSpacing.base)
        .background(palette.surface, in: RoundedRectangle(cornerRadius: RBRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: RBRadius.card, style: .continuous)
                .stroke(palette.border, lineWidth: 1)
        }
        .shadow(color: RBShadow.card.color, radius: RBShadow.card.radius, x: RBShadow.card.x, y: RBShadow.card.y)
    }
}

#Preview("Campaign card") {
    RBCampaignCard(title: "Library fundraiser") {
        RoundedRectangle(cornerRadius: RBRadius.field, style: .continuous)
            .fill(RBColor.accent.opacity(0.25))
    } metadata: {
        Text("₴42,000 of ₴60,000")
            .font(RBTypography.microLabel)
            .foregroundStyle(RBColor.mutedInk)
    }
    .padding()
    .rbTheme(.light)
}

#Preview("Campaign card dark") {
    RBCampaignCard(title: "Library fundraiser") {
        RoundedRectangle(cornerRadius: RBRadius.field, style: .continuous)
            .fill(RBColor.accent.opacity(0.25))
    } metadata: {
        Text("₴42,000 of ₴60,000")
            .font(RBTypography.microLabel)
            .foregroundStyle(RBColor.darkMutedInk)
    }
    .padding()
    .background(RBThemePalette.dark.app)
    .rbTheme(.dark)
}
