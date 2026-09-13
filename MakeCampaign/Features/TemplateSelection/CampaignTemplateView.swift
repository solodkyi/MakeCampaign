import SwiftUI

struct CampaignTemplateView: View {
    let campaign: Campaign
    let template: Template
    let image: UIImage?
    let onImageTransformEnd: ((CGFloat, CGSize, CGSize) -> Void)?
    
    private var isRepositioningEnabled: Bool {
        onImageTransformEnd != nil
    }
    
    init(
        campaign: Campaign,
        template: Template,
        image: UIImage? = nil,
        onImageTransformEnd: ((CGFloat, CGSize, CGSize) -> Void)? = nil
    ) {
        self.campaign = campaign
        self.template = template
        self.image = image
        self.onImageTransformEnd = onImageTransformEnd
    }
    
    @ViewBuilder
    var body: some View {
        if let image, isRepositioningEnabled {
            InteractiveCampaignTemplateView(
                campaign: campaign,
                template: template,
                image: image,
                onImageTransformEnd: onImageTransformEnd
            )
        } else {
            CampaignTemplateArtwork(campaign: campaign, template: template) {
                staticContent()
            }
        }
    }

    @ViewBuilder
    private func staticContent() -> some View {
        if let image {
            DisplayImageView(
                image: image,
                scale: campaign.imageScale,
                offset: campaign.imageOffset,
                referenceSize: campaign.imageReferenceSize,
                contentMode: campaign.image?.contentMode ?? .fill
            )
        } else {
            Color.white
        }
    }
}

private struct InteractiveCampaignTemplateView: View {
    let campaign: Campaign
    let template: Template
    let image: UIImage
    let onImageTransformEnd: ((CGFloat, CGSize, CGSize) -> Void)?

    @State private var interaction = CampaignPhotoInteractionState()

    var body: some View {
        CampaignTemplateArtwork(campaign: campaign, template: template) {
            CampaignPosterPhotoPreview(
                image: image,
                initialOffset: campaign.imageOffset,
                initialScale: campaign.imageScale,
                referenceSize: campaign.imageReferenceSize,
                contentMode: campaign.image?.contentMode ?? .fill,
                allowsImageTransform: true,
                interaction: interaction,
                onTransformEnd: onImageTransformEnd
            )
        }
        .campaignPhotoOverflowPreviewEnabled(true)
        .campaignPhotoTransformIsActive(interaction.isActive)
    }
}

struct CampaignTemplateArtwork<PhotoContent: View>: View {
    let campaign: Campaign
    let template: Template
    /// Тести малюють окремі грошові стани, яких збір виразити не може, —
    /// тоді стан передають напряму.
    let funding: CampaignPosterFunding?
    private let photoContent: PhotoContent

    init(
        campaign: Campaign,
        template: Template,
        funding: CampaignPosterFunding? = nil,
        @ViewBuilder photoContent: () -> PhotoContent
    ) {
        self.campaign = campaign
        self.template = template
        self.funding = funding
        self.photoContent = photoContent()
    }

    var body: some View {
        templateView(forTemplate: template)
    }

    @ViewBuilder
    private func templateView(forTemplate template: Template) -> some View {
        let purpose = campaign.posterPurpose

        let funding = self.funding ?? CampaignPosterFunding(campaign: campaign)

        switch template.series {
        case .b:
            seriesB(template, purpose: purpose, funding: funding)
        case .a:
            seriesA(template, purpose: purpose, funding: funding)
        }
    }

    /// Набір B — свіжий погляд.
    @ViewBuilder
    private func seriesB(
        _ template: Template,
        purpose: String,
        funding: CampaignPosterFunding
    ) -> some View {
        switch (template.gradient, template.imagePlacement) {
        case (.linearPurple, .topCenter):
            PurpleGradientTemplateView(purpose: purpose, funding: funding, viewProvider: {
                content()
            })
        case (.linearGreen, .topToBottomTrailing):
            GreenGradientTemplateView(purpose: purpose, funding: funding, viewProvider: {
                content()
            })
        case (.angularYellowBlue, .trailing):
            YellowBlueGradientTemplateView(purpose: purpose, funding: funding, viewProvider: {
                content()
            })
        case (.linearSilverBlue, .trailingToEdge):
            SilverBlueTemplateView(purpose: purpose, funding: funding, viewProvider: {
                content()
            })
        case (.linearCoralTeal, .trailing):
            CoralTealGradientTemplateView(purpose: purpose, funding: funding, viewProvider: {
                content()
            })
        case (.radialRedBlack, .topToEdge):
            RedBlackGradientTemplateView(purpose: purpose, funding: funding, viewProvider: {
                content()
            })
        case (.blueLinear, .center):
            BlueGradientTemplateView(purpose: purpose, funding: funding, viewProvider: {
                content()
            })
        case (.cyanMagentaRadial, .squareTrailing):
            CyanMagentaGradientTemplateView(purpose: purpose, funding: funding, viewProvider: {
                content()
            })
        case (.radialAquaPurple, .squareTrailing):
            AquaPurpleGradientTemplateView(purpose: purpose, funding: funding, viewProvider: {
                content()
            })
        case (.goldBlackLinear, .hexagonTrailing):
            GoldBlackGradientTemplateView(purpose: purpose, funding: funding, viewProvider: {
                content()
            })
        case (.linearEmeraldBlack, .hexagonTrailing):
            EmeraldBlackGradientTemplateView(purpose: purpose, funding: funding, viewProvider: {
                content()
            })
        case (.pinkAngular, .topCenter):
            PinkGradientTemplateView(purpose: purpose, funding: funding, viewProvider: {
                content()
            })
        case (.tealPurpleRadial, .roundedTrailing):
            TealPurpleGradientTemplateView(purpose: purpose, funding: funding, viewProvider: {
                content()
            })
        case (.radialMintIndigo, .roundedTrailing):
            MintIndigoGradientTemplateView(purpose: purpose, funding: funding, viewProvider: {
                content()
            })
        case (.linearIndigoOrange, .trailing):
            IndigoOrangeGradientTemplateView(purpose: purpose, funding: funding, viewProvider: {
                content()
            })
        default: EmptyView()
        }
    }

    /// Набір A — перша ітерація.
    @ViewBuilder
    private func seriesA(
        _ template: Template,
        purpose: String,
        funding: CampaignPosterFunding
    ) -> some View {
        switch (template.gradient, template.imagePlacement) {
        case (.blueLinear, .center):
            PosterA01TemplateView(purpose: purpose, funding: funding, viewProvider: {
                content()
            })
        case (.cyanMagentaRadial, .squareTrailing):
            PosterA02TemplateView(purpose: purpose, funding: funding, viewProvider: {
                content()
            })
        case (.linearPurple, .topCenter):
            PosterA03TemplateView(purpose: purpose, funding: funding, viewProvider: {
                content()
            })
        case (.goldBlackLinear, .hexagonTrailing):
            PosterA04TemplateView(purpose: purpose, funding: funding, viewProvider: {
                content()
            })
        case (.pinkAngular, .topCenter):
            PosterA05TemplateView(purpose: purpose, funding: funding, viewProvider: {
                content()
            })
        case (.tealPurpleRadial, .roundedTrailing):
            PosterA06TemplateView(purpose: purpose, funding: funding, viewProvider: {
                content()
            })
        case (.linearGreen, .topToBottomTrailing):
            PosterA07TemplateView(purpose: purpose, funding: funding, viewProvider: {
                content()
            })
        case (.angularYellowBlue, .trailing):
            PosterA08TemplateView(purpose: purpose, funding: funding, viewProvider: {
                content()
            })
        case (.linearSilverBlue, .trailingToEdge):
            PosterA09TemplateView(purpose: purpose, funding: funding, viewProvider: {
                content()
            })
        case (.radialRedBlack, .topToEdge):
            PosterA10TemplateView(purpose: purpose, funding: funding, viewProvider: {
                content()
            })
        case (.linearIndigoOrange, .trailing):
            PosterA11TemplateView(purpose: purpose, funding: funding, viewProvider: {
                content()
            })
        case (.linearEmeraldBlack, .hexagonTrailing):
            PosterA12TemplateView(purpose: purpose, funding: funding, viewProvider: {
                content()
            })
        case (.radialAquaPurple, .squareTrailing):
            PosterA13TemplateView(purpose: purpose, funding: funding, viewProvider: {
                content()
            })
        case (.radialMintIndigo, .roundedTrailing):
            PosterA14TemplateView(purpose: purpose, funding: funding, viewProvider: {
                content()
            })
        case (.linearCoralTeal, .trailing):
            PosterA15TemplateView(purpose: purpose, funding: funding, viewProvider: {
                content()
            })
        default: EmptyView()
        }
    }

    @ViewBuilder
    private func content() -> some View {
        photoContent.campaignPosterElement(.photo)
    }
}

extension Campaign {
    var posterPurpose: String {
        purpose.isEmpty ? "Назва збору" : purpose
    }
}

struct DisplayImageView: View {
    let image: UIImage
    let scale: CGFloat
    let offset: CGSize
    let referenceSize: CGSize
    let contentMode: Campaign.Image.ContentMode
    var clipsToBounds = true
    
    var body: some View {
        GeometryReader { geometry in
            let currentWidth = geometry.size.width
            let currentHeight = geometry.size.height
            
            let referenceWidth = referenceSize.width
            let referenceHeight = referenceSize.height
            
            let scaledOffset: CGSize = {
                if referenceWidth > 0 && referenceHeight > 0 {
                    let relativeOffsetX = offset.width / referenceWidth
                    let relativeOffsetY = offset.height / referenceHeight
                    
                    return CGSize(
                        width: relativeOffsetX * currentWidth,
                        height: relativeOffsetY * currentHeight
                    )
                } else {
                    return offset
                }
            }()
            
            Group {
                if contentMode == .fit {
                    Image(uiImage: image).resizable().scaledToFit()
                } else {
                    Image(uiImage: image).resizable().scaledToFill()
                }
            }
            .scaleEffect(max(0.1, scale))
            .offset(scaledOffset)
            .applyIf(clipsToBounds) { view in
                view.clipped()
            }
        }
    }
}

struct ImageTransformView: View {
    private enum ActiveGesture: Hashable {
        case drag
        case magnification
    }

    let image: UIImage
    let initialOffset: CGSize
    let initialScale: CGFloat
    let containerSize: CGSize
    let referenceSize: CGSize
    let contentMode: Campaign.Image.ContentMode
    let onTransformEnd: ((CGFloat, CGSize, CGSize) -> Void)?
    let onTransformActivityChanged: ((Bool) -> Void)?
    let onTransformChanged: ((CGFloat, CGSize, CGSize) -> Void)?

    @State private var offset: CGSize
    @State private var scale: CGFloat
    @State private var dragStartOffset: CGSize = .zero
    @State private var activeGestures: Set<ActiveGesture> = []

    private var isRepositioningEnabled: Bool {
        onTransformEnd != nil
    }

    /// `initialOffset` is stored against the container it was captured in, which
    /// is what `referenceSize` records. Displaying it in a container of another
    /// size means scaling it back into that container's coordinate space — the
    /// same conversion `DisplayImageView` performs. Applying it raw makes the
    /// editor and the exported artwork disagree about where the photo sits
    /// wherever the photo frame is not the size the offset was recorded against.
    private static func scaledOffset(
        _ offset: CGSize,
        from referenceSize: CGSize,
        to containerSize: CGSize
    ) -> CGSize {
        guard referenceSize.width > 0, referenceSize.height > 0 else { return offset }

        return CGSize(
            width: offset.width / referenceSize.width * containerSize.width,
            height: offset.height / referenceSize.height * containerSize.height
        )
    }

    private var resolvedInitialOffset: CGSize {
        Self.scaledOffset(initialOffset, from: referenceSize, to: containerSize)
    }

    init(
        image: UIImage,
        initialOffset: CGSize,
        initialScale: CGFloat,
        containerSize: CGSize,
        referenceSize: CGSize = .zero,
        contentMode: Campaign.Image.ContentMode = .fill,
        onTransformEnd: ((CGFloat, CGSize, CGSize) -> Void)? = nil,
        onTransformActivityChanged: ((Bool) -> Void)? = nil,
        onTransformChanged: ((CGFloat, CGSize, CGSize) -> Void)? = nil
    ) {
        self.image = image
        self.initialOffset = initialOffset
        self.initialScale = initialScale
        self.containerSize = containerSize
        self.referenceSize = referenceSize
        self.contentMode = contentMode
        self.onTransformEnd = onTransformEnd
        self.onTransformActivityChanged = onTransformActivityChanged
        self.onTransformChanged = onTransformChanged
        _offset = State(
            initialValue: Self.scaledOffset(
                initialOffset, from: referenceSize, to: containerSize
            )
        )
        _scale = State(initialValue: initialScale)
    }
    
    var body: some View {
        Group {
            if contentMode == .fit {
                Image(uiImage: image).resizable().scaledToFit()
            } else {
                Image(uiImage: image).resizable().scaledToFill()
            }
        }
            .scaleEffect(max(0.1, scale))
            .offset(offset)
            .clipped()
            .onChange(of: initialOffset) { _, _ in
                offset = resolvedInitialOffset
            }
            .onChange(of: initialScale) { _, newScale in
                scale = max(0.1, newScale)
            }
            .applyIf(isRepositioningEnabled) { view in
                view
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                begin(.drag)
                                let newOffset = CGSize(
                                    width: dragStartOffset.width + gesture.translation.width,
                                    height: dragStartOffset.height + gesture.translation.height
                                )
                                offset = newOffset
                                onTransformChanged?(scale, newOffset, containerSize)
                            }
                            .onEnded { _ in
                                dragStartOffset = offset
                                onTransformEnd?(scale, offset, containerSize)
                                end(.drag)
                            }
                    )
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                begin(.magnification)
                                let newScale = max(0.1, value)
                                scale = newScale
                                onTransformChanged?(newScale, offset, containerSize)
                            }
                            .onEnded { value in
                                scale = max(0.1, value)
                                onTransformChanged?(scale, offset, containerSize)
                                onTransformEnd?(scale, offset, containerSize)
                                end(.magnification)
                            }
                    )
            }
            .onAppear {
                dragStartOffset = resolvedInitialOffset
            }
            .onDisappear {
                activeGestures.removeAll()
                onTransformActivityChanged?(false)
            }
    }

    private func begin(_ gesture: ActiveGesture) {
        let wasInactive = activeGestures.isEmpty
        activeGestures.insert(gesture)
        if wasInactive {
            onTransformActivityChanged?(true)
        }
    }

    private func end(_ gesture: ActiveGesture) {
        activeGestures.remove(gesture)
        if activeGestures.isEmpty {
            onTransformActivityChanged?(false)
        }
    }
}

extension View {
    @ViewBuilder
    func applyIf<Content: View>(_ condition: Bool, content: (Self) -> Content) -> some View {
        if condition {
            content(self)
        } else {
            self
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        Text("Repositioning Enabled")
            .font(.headline)
        
        CampaignTemplateView(
            campaign: .mock1,
            template: Template(name: "1", gradient: .linearPurple, imagePlacement: .topCenter),
            image: UIImage(data: Campaign.mock1.image!.raw!) ?? UIImage(),
            onImageTransformEnd: { _, _, _ in }
        )
        
        Text("Repositioning Disabled")
            .font(.headline)
        
        CampaignTemplateView(
            campaign: .mock1,
            template: Template(name: "1", gradient: .linearPurple, imagePlacement: .topCenter),
            image: UIImage(data: Campaign.mock1.image!.raw!) ?? UIImage()
        )
    }
} 
