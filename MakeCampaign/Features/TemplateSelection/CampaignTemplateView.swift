import SwiftUI
import ComposableArchitecture

struct CampaignTemplateView: View {
    let campaign: Campaign
    let template: Template
    let image: UIImage
    let onImageTransformEnd: ((CGFloat, CGSize, CGSize) -> Void)?
    
    private var isRepositioningEnabled: Bool {
        onImageTransformEnd != nil
    }
    
    init(
        campaign: Campaign,
        template: Template,
        image: UIImage,
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
        let purpose = campaign.purpose
        let goal = campaign.target?.formattedAmount.appendingCurrency
        
        switch (template.gradient, template.imagePlacement) {
        case (.linearPurple, .topCenter):
            PurpleGradientTemplateView(purpose: purpose, goal: goal, viewProvider: {
                imageView()
            })
        case (.linearGreen, .topToBottomTrailing):
            GreenGradientTemplateView(purpose: purpose, goal: goal, viewProvider: {
                imageView()
            })
        case (.angularYellowBlue, .trailing):
            YellowBlueGradientTemplateView(purpose: purpose, goal: goal, viewProvider: {
                imageView()
            })
        case (.linearSilverBlue, .trailingToEdge):
            SilverBlueTemplateView(purpose: purpose, goal: goal, viewProvider: {
                imageView()
            })
        case (.radialRedBlack, .topToEdge):
            RedBlackGradientTemplateView(purpose: purpose, goal: goal, viewProvider: {
                imageView()
            })
        default: EmptyView()
        }
    }
    
    private func imageView() -> some View {
        if isRepositioningEnabled {
            // Full transform functionality for editing mode
            AnyView(
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
            // Simplified display view that applies stored transforms
            AnyView(
                DisplayImageView(
                    image: image,
                    scale: campaign.imageScale,
                    offset: campaign.imageOffset,
                    referenceSize: campaign.imageReferenceSize
                )
            )
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
            // Get current container dimensions
            let currentWidth = geometry.size.width
            let currentHeight = geometry.size.height
            
            // Use the stored reference size for accurate scaling
            let referenceWidth = referenceSize.width
            let referenceHeight = referenceSize.height
            
            // Calculate relative offset (as percentage of container)
            let relativeOffsetX = offset.width / referenceWidth
            let relativeOffsetY = offset.height / referenceHeight
            
            // Convert back to absolute offset for current container
            let scaledOffset = CGSize(
                width: relativeOffsetX * currentWidth,
                height: relativeOffsetY * currentHeight
            )
            
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
                                offset = gesture.translation
                            }
                            .onEnded { _ in
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
