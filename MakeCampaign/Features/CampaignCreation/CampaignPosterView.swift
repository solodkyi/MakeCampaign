import Observation
import SwiftUI

@Observable
final class CampaignPhotoInteractionState {
    struct Transform {
        let scale: CGFloat
        let offset: CGSize
        let referenceSize: CGSize
    }

    var isActive = false
    var transform: Transform?
}

enum CampaignPosterLayout {
    static func previewSize(
        for format: Campaign.PosterFormat,
        in availableSize: CGSize
    ) -> CGSize {
        let pixelSize = format.pixelSize
        guard pixelSize.width > 0,
              pixelSize.height > 0,
              availableSize.width > 0,
              availableSize.height > 0 else {
            return .zero
        }
        let scale = min(
            availableSize.width / pixelSize.width,
            availableSize.height / pixelSize.height
        )
        return CGSize(width: pixelSize.width * scale, height: pixelSize.height * scale)
    }

    static func qrSideLength(for posterShortestSide: CGFloat) -> CGFloat {
        posterShortestSide * 0.12
    }
}

enum CampaignPosterInteractionPolicy {
    static func isEnabled(
        isTransformingImage: Bool,
        hasCallbacks: Bool
    ) -> Bool {
        !isTransformingImage && hasCallbacks
    }
}

struct CampaignPosterView: View {
    let campaign: Campaign
    let assets: CampaignPosterPreviewAssets
    var allowsImageTransform = false
    var selectedElement: CampaignPosterElement? = nil
    var onContentModeSelect: ((Campaign.Image.ContentMode) -> Void)?
    var onImageTransformEnd: ((CGFloat, CGSize, CGSize) -> Void)?
    var onElementTap: ((CampaignPosterElement) -> Void)?
    var onElementDoubleTap: ((CampaignPosterElement) -> Void)?
    var onBackgroundTap: (() -> Void)?

    @State private var elementRegions: [CampaignPosterElement: CGRect] = [:]
    @State private var isContentModePopoverPresented = false
    @State private var photoInteraction = CampaignPhotoInteractionState()

    var body: some View {
        CampaignPosterArtwork(campaign: campaign, qrCode: assets.qrCode) {
            if let photo = assets.photo {
                photoPreview(photo)
            } else {
                CampaignPosterPlaceholder(campaign: campaign)
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: .center
                    )
            }
        }
        .campaignPhotoOverflowPreviewEnabled(allowsImageTransform)
        .campaignPhotoTransformIsActive(photoInteraction.isActive)
        .campaignPosterCoordinateSpace()
        .campaignPosterInteractivityEnabled(elementsAreInteractive)
        .campaignPosterRegionTrackingEnabled(tracksElementRegions)
        .campaignPosterAccessibilityActions(
            select: onElementTap,
            edit: onElementDoubleTap
        )
        .campaignPosterSelection(selectedElement)
        .onPreferenceChange(CampaignPosterElementRegionPreferenceKey.self) {
            elementRegions = $0
        }
        .overlay {
            selectionBorder
        }
        .overlay {
            GeometryReader { _ in
                photoContentModeControl
            }
        }
        .contentShape(Rectangle())
        .applyIf(isInteractive) { view in
            view.simultaneousGesture(posterTapGesture)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Попередній перегляд постера")
        .accessibilityIdentifier("campaign-poster-preview")
    }

    private var isInteractive: Bool {
        onElementTap != nil || onElementDoubleTap != nil || onBackgroundTap != nil
    }

    private var elementsAreInteractive: Bool {
        onElementTap != nil || onElementDoubleTap != nil
    }

    private var tracksElementRegions: Bool {
        CampaignPosterInteractionPolicy.isEnabled(
            isTransformingImage: photoInteraction.isActive,
            hasCallbacks: onElementTap != nil
                || onElementDoubleTap != nil
                || (selectedElement == .photo && onContentModeSelect != nil)
        )
    }

    private var posterTapGesture: some Gesture {
        SpatialTapGesture(count: 2)
            .exclusively(before: SpatialTapGesture(count: 1))
            .onEnded { value in
                switch value {
                case let .first(doubleTap):
                    handleTap(at: doubleTap.location, isDoubleTap: true)
                case let .second(singleTap):
                    handleTap(at: singleTap.location, isDoubleTap: false)
                }
            }
    }

    private func handleTap(at location: CGPoint, isDoubleTap: Bool) {
        let element = CampaignPosterHitTesting.element(at: location, in: elementRegions)
        guard let element else {
            onBackgroundTap?()
            return
        }

        if isDoubleTap {
            onElementDoubleTap?(element)
        } else {
            onElementTap?(element)
        }
    }

    @ViewBuilder
    private var selectionBorder: some View {
        if let selectedElement,
           let frame = elementRegions[selectedElement] {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(.white.opacity(0.92), lineWidth: 5)
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(Color(red: 0.88, green: 0.34, blue: 0.16), lineWidth: 2.5)
            }
            .frame(width: frame.width, height: frame.height)
            .position(x: frame.midX, y: frame.midY)
            .accessibilityHidden(true)
            .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var photoContentModeControl: some View {
        if selectedElement == .photo,
           onContentModeSelect != nil,
           let frame = elementRegions[.photo] {
            photoContentModeMenu
                .position(x: frame.maxX - 23, y: frame.maxY - 23)
        }
    }

    private var photoContentModeMenu: some View {
        Button {
            isContentModePopoverPresented = true
        } label: {
            Image(systemName: "crop")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(red: 0.88, green: 0.34, blue: 0.16))
                .frame(width: 32, height: 32)
                .background(.regularMaterial, in: Circle())
                .overlay {
                    Circle()
                        .stroke(.white.opacity(0.92), lineWidth: 2)
                }
        }
        .frame(width: 32, height: 32)
        .contentShape(Circle())
        .fixedSize()
        .buttonStyle(.plain)
        .accessibilityLabel("Режим фото")
        .accessibilityValue(contentModeTitle(campaign.image?.contentMode ?? .fill))
        .accessibilityIdentifier("photo-content-mode-menu")
        .popover(
            isPresented: $isContentModePopoverPresented,
            attachmentAnchor: .rect(.bounds),
            arrowEdge: .bottom
        ) {
            VStack(spacing: 0) {
                contentModeButton(.fill, title: "Заповнити")
                Divider()
                contentModeButton(.fit, title: "Вмістити")
            }
            .padding(8)
            .presentationCompactAdaptation(.popover)
        }
    }

    private func contentModeButton(
        _ contentMode: Campaign.Image.ContentMode,
        title: String
    ) -> some View {
        Button {
            isContentModePopoverPresented = false
            onContentModeSelect?(contentMode)
        } label: {
            HStack {
                Text(title)
                Spacer(minLength: 20)
                if (campaign.image?.contentMode ?? .fill) == contentMode {
                    Image(systemName: "checkmark")
                }
            }
            .frame(minWidth: 150, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 11)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("photo-content-mode-\(contentMode.rawValue)")
    }

    private func contentModeTitle(_ contentMode: Campaign.Image.ContentMode) -> String {
        switch contentMode {
        case .fill: "Заповнити"
        case .fit: "Вмістити"
        }
    }

    @ViewBuilder
    private func photoPreview(_ image: UIImage) -> some View {
        CampaignPosterPhotoPreview(
            image: image,
            initialOffset: campaign.imageOffset,
            initialScale: campaign.imageScale,
            referenceSize: campaign.imageReferenceSize,
            contentMode: campaign.image?.contentMode ?? .fill,
            allowsImageTransform: allowsImageTransform,
            interaction: photoInteraction,
            onTransformEnd: onImageTransformEnd
        )
    }

}

struct CampaignPosterPhotoPreview: View {
    let image: UIImage
    let initialOffset: CGSize
    let initialScale: CGFloat
    let referenceSize: CGSize
    let contentMode: Campaign.Image.ContentMode
    let allowsImageTransform: Bool
    let interaction: CampaignPhotoInteractionState
    let onTransformEnd: ((CGFloat, CGSize, CGSize) -> Void)?

    @Environment(\.campaignPhotoLayer) private var photoLayer

    @ViewBuilder
    var body: some View {
        if allowsImageTransform, photoLayer == .overflow {
            let transform = interaction.transform ?? .init(
                scale: initialScale,
                offset: initialOffset,
                referenceSize: referenceSize
            )
            DisplayImageView(
                image: image,
                scale: transform.scale,
                offset: transform.offset,
                referenceSize: transform.referenceSize,
                contentMode: contentMode,
                clipsToBounds: false
            )
        } else if allowsImageTransform {
            GeometryReader { geometry in
                ImageTransformView(
                    image: image,
                    initialOffset: initialOffset,
                    initialScale: initialScale,
                    containerSize: geometry.size,
                    referenceSize: referenceSize,
                    contentMode: contentMode,
                    onTransformEnd: onTransformEnd,
                    onTransformActivityChanged: { isActive in
                        interaction.isActive = isActive
                        if !isActive {
                            interaction.transform = nil
                        }
                    },
                    onTransformChanged: { scale, offset, referenceSize in
                        interaction.transform = .init(
                            scale: scale,
                            offset: offset,
                            referenceSize: referenceSize
                        )
                    }
                )
            }
        } else {
            DisplayImageView(
                image: image,
                scale: initialScale,
                offset: initialOffset,
                referenceSize: referenceSize,
                contentMode: contentMode
            )
        }
    }
}

struct CampaignPosterPlaceholder: View {
    let campaign: Campaign

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.badge.plus")
                .font(.system(size: 42, weight: .light))
            Text(campaign.purpose.isEmpty ? "Фото" : campaign.purpose)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .accessibilityIdentifier("campaign-poster-placeholder")
        }
        .foregroundStyle(.black.opacity(0.5))
    }
}
