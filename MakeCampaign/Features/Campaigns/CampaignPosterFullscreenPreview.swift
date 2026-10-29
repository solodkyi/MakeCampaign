import Dependencies
import SwiftUI

/// Постер на весь екран — таким, яким його побачать у сторіс і чатах, без
/// редактора довкола.
///
/// Малює той самий `CampaignPosterView`, що й редактор, лише без жодних
/// обробників дотиків: це перегляд, а не полотно. Чорне тло — бо постер
/// живе в чужих стрічках, і нейтральна рамка застосунку тут лише заважала б
/// оцінити кольори.
struct CampaignPosterFullscreenPreview: View {
    let campaign: Campaign

    @Dependency(\.campaignPosterPreviewAssetLoader) private var previewAssetLoader
    @Environment(\.dismiss) private var dismiss
    @State private var assetBuffer = CampaignPosterPreviewAssetBuffer()
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            let posterSize = CampaignPosterLayout.previewSize(
                for: campaign.posterFormat,
                in: CGSize(
                    width: geometry.size.width - Self.margin * 2,
                    height: geometry.size.height - Self.margin * 2
                )
            )

            CampaignPosterView(campaign: campaign, assets: assetBuffer.assets)
                .frame(width: posterSize.width, height: posterSize.height)
                .shadow(color: .black.opacity(0.5), radius: 30, y: 12)
                .scaleEffect(posterScale)
                .offset(y: dragOffset)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.black.opacity(backdropOpacity).ignoresSafeArea())
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .tint(.white)
            .padding(.trailing, 16)
            .padding(.top, 8)
            .opacity(backdropOpacity)
            .accessibilityLabel("Закрити")
            .accessibilityIdentifier("campaign-poster-fullscreen-close")
        }
        .contentShape(Rectangle())
        .gesture(dismissDrag)
        // Прозора основа, щоб під час перетягування крізь чорне тло
        // проступав список, до якого постер повертається.
        .presentationBackground(.clear)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("campaign-poster-fullscreen")
        .accessibilityAction(.escape) { dismiss() }
        .task(id: assetInput) {
            assetBuffer.beginLoading(assetInput)
            do {
                let assets = try await previewAssetLoader.load(assetInput)
                try Task.checkCancellation()
                assetBuffer.commit(assets, for: assetInput)
            } catch {
                guard !Task.isCancelled else { return }
            }
        }
    }

    /// Постер можна зсунути вниз, як фото в Галереї: він іде за пальцем, тло
    /// світлішає, а відпущений досить далеко чи досить швидко — закривається.
    /// Угору постер пручається, бо там немає куди йти.
    private var dismissDrag: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                let height = value.translation.height
                dragOffset = height > 0 ? height : height / 4
            }
            .onEnded { value in
                let isFarEnough = value.translation.height > Self.dismissDistance
                let isFlung = value.predictedEndTranslation.height > Self.dismissDistance * 2.5
                if isFarEnough || isFlung {
                    dismiss()
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        dragOffset = 0
                    }
                }
            }
    }

    private var dragProgress: CGFloat {
        min(max(dragOffset, 0) / (Self.dismissDistance * 3), 1)
    }

    private var backdropOpacity: Double {
        1 - dragProgress * 0.8
    }

    private var posterScale: CGFloat {
        1 - dragProgress * 0.15
    }

    private static let dismissDistance: CGFloat = 140

    private var assetInput: CampaignPosterPreviewAssetInput {
        CampaignPosterPreviewAssetInput(campaign: campaign)
    }

    private static let margin: CGFloat = 16
}

#Preview("Квадрат") {
    withDependencies {
        $0.campaignPosterPreviewAssetLoader = .liveValue
    } operation: {
        CampaignPosterFullscreenPreview(campaign: .mock2)
    }
}

#Preview("Сторіс") {
    withDependencies {
        $0.campaignPosterPreviewAssetLoader = .liveValue
    } operation: {
        var campaign = Campaign.mock1
        campaign.posterFormat = .story
        return CampaignPosterFullscreenPreview(campaign: campaign)
    }
}
