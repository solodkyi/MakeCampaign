import SwiftUI
import ComposableArchitecture

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
    
    var body: some View {
        templateView(forTemplate: template)
    }
    
    @ViewBuilder
    private func templateView(forTemplate template: Template) -> some View {
        
        let purpose: String = {
            if campaign.purpose.isEmpty {
                return "Текст текст"
            }
            return campaign.purpose
        }()
        
        let goal = campaign.target?.formattedAmount.appendingCurrency
        
        switch (template.gradient, template.imagePlacement) {
        case (.linearPurple, .topCenter):
            PurpleGradientTemplateView(purpose: purpose, goal: goal, viewProvider: {
                content()
            })
        case (.linearGreen, .topToBottomTrailing):
            GreenGradientTemplateView(purpose: purpose, goal: goal, viewProvider: {
                content()
            })
        case (.angularYellowBlue, .trailing):
            YellowBlueGradientTemplateView(purpose: purpose, goal: goal, viewProvider: {
                content()
            })
        case (.linearSilverBlue, .trailingToEdge):
            SilverBlueTemplateView(purpose: purpose, goal: goal, viewProvider: {
                content()
            })
        case (.radialRedBlack, .topToEdge):
            RedBlackGradientTemplateView(purpose: purpose, goal: goal, viewProvider: {
                content()
            })
        case (.blueLinear, .center):
            BlueGradientTemplateView(purpose: purpose, goal: goal, viewProvider: {
                content()
            })
        case (.cyanMagentaRadial, .squareTrailing):
            CyanMagentaGradientTemplateView(purpose: purpose, goal: goal, viewProvider: {
                content()
            })
        case (.goldBlackLinear, .hexagonTrailing):
            GoldBlackGradientTemplateView(purpose: purpose, goal: goal, viewProvider: {
                content()
            })
        case (.pinkAngular, .topCenter):
            PinkGradientTemplateView(purpose: purpose, goal: goal, viewProvider: {
                content()
            })
        case (.tealPurpleRadial, .roundedTrailing):
            TealPurpleGradientTemplateView(purpose: purpose, goal: goal, viewProvider: {
                content()
            })
        default: EmptyView()
        }
    }
    
    private func content() -> some View {
        if let image {
            if isRepositioningEnabled {
                return AnyView(
                    GeometryReader { geometry in
                        let initialOffset = campaign.imageOffset
                        let initialScale = campaign.imageScale
                        
                        ImageTransformView(
                            image: image,
                            initialOffset: initialOffset,
                            initialScale: initialScale,
                            containerSize: geometry.size,
                            onTransformEnd: onImageTransformEnd
                        )
                    }
                )
            } else {
                return AnyView(
                    DisplayImageView(
                        image: image,
                        scale: campaign.imageScale,
                        offset: campaign.imageOffset,
                        referenceSize: campaign.imageReferenceSize
                    )
                )
            }
        } else {
            return AnyView(Color.white)
        }
    }
}

struct DisplayImageView: View {
    let image: UIImage
    let scale: CGFloat
    let offset: CGSize
    let referenceSize: CGSize
    
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
            
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .scaleEffect(max(0.1, scale))
                .offset(scaledOffset)
        }
    }
}

struct ImageTransformView: View {
    let image: UIImage
    let initialOffset: CGSize
    let initialScale: CGFloat
    let containerSize: CGSize
    let onTransformEnd: ((CGFloat, CGSize, CGSize) -> Void)?
    
    @State private var offset: CGSize
    @State private var scale: CGFloat
    @State private var dragStartOffset: CGSize = .zero
    
    private var isRepositioningEnabled: Bool {
        onTransformEnd != nil
    }
    
    init(
        image: UIImage,
        initialOffset: CGSize,
        initialScale: CGFloat,
        containerSize: CGSize,
        onTransformEnd: ((CGFloat, CGSize, CGSize) -> Void)? = nil
    ) {
        self.image = image
        self.initialOffset = initialOffset
        self.initialScale = initialScale
        self.containerSize = containerSize
        self.onTransformEnd = onTransformEnd
        _offset = State(initialValue: initialOffset)
        _scale = State(initialValue: initialScale)
    }
    
    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .scaleEffect(max(0.1, scale))
            .offset(offset)
            .clipped()
            .onChange(of: initialOffset) { newOffset in
                offset = newOffset
            }
            .onChange(of: initialScale) { newScale in
                scale = max(0.1, newScale)
            }
            .applyIf(isRepositioningEnabled) { view in
                view
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                offset = CGSize(
                                    width: dragStartOffset.width + gesture.translation.width,
                                    height: dragStartOffset.height + gesture.translation.height
                                )
                            }
                            .onEnded { _ in
                                dragStartOffset = offset
                                onTransformEnd?(scale, offset, containerSize)
                            }
                    )
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = max(0.1, value)
                            }
                            .onEnded { value in
                                scale = max(0.1, value)
                                onTransformEnd?(scale, offset, containerSize)
                            }
                    )
            }
            .onAppear {
                dragStartOffset = initialOffset
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
