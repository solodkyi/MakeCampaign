import SwiftUI
import ComposableArchitecture

struct TemplateSelectionFeature: Reducer {
    struct State: Equatable {
        var campaign: Campaign
        var selectedTemplateID: Template.ID?
        var templates: IdentifiedArrayOf<Template> = Template.list
        
        var selectedTemplate: Template? {
            selectedTemplateID.flatMap { id in templates[id: id] }
        }
        
        init(campaign: Campaign, templates: IdentifiedArrayOf<Template> = Template.list, selectedTemplateID: Template.ID? = nil) {
            self.campaign = campaign
            self.templates = templates
            self.selectedTemplateID = campaign.template?.id
        }
    }
    
    @Dependency(\.dismiss) var dismiss
    
    enum Action: Equatable {
        case onAppear
        case templateSelected(Template)
        case delegate(Delegate)
        case doneButtonTapped
        case onImageRepositionFinished(CGFloat, CGSize)
        
        enum Delegate: Equatable {
            case templateApplied(Template, forCampaign: Campaign.ID)
            case imageRepositioned(CGFloat, CGSize, forCampaign: Campaign.ID)
        }
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .none
                
            case let .templateSelected(template):
                state.selectedTemplateID = template.id
                state.campaign.imageScale = 1
                state.campaign.imageOffset = .zero
                
                return .send(.delegate(.imageRepositioned(1, .zero, forCampaign: state.campaign.id)))

            case .doneButtonTapped:
                if let templateID = state.selectedTemplateID,
                   let template = state.templates[id: templateID] {
                    return .run { [state] send in
                        await send(.delegate(.templateApplied(template, forCampaign: state.campaign.id)))
                        await self.dismiss()
                    }
                }
                return .none
            case let .onImageRepositionFinished(scale, offset):
                state.campaign.imageScale = scale
                state.campaign.imageOffset = offset
                
                return .send(.delegate(.imageRepositioned(scale, offset, forCampaign: state.campaign.id)))
            case .delegate:
                return .none
            }
        }
    }
}

struct TemplateSelectionView: View {
    let store: StoreOf<TemplateSelectionFeature>
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            VStack(spacing: 0) {
                ZStack {
                    if let imageData = viewStore.campaign.image?.raw,
                       let uiImage = UIImage(data: imageData) {
                        if let selectedTemplate = viewStore.selectedTemplate {
                            templateView(forTemplate: selectedTemplate, viewStore: viewStore, image: uiImage)
                        } else {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                        }
                    } else {
                        Text("Неможливо завантажити зображення")
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
                .background(Color(.systemGroupedBackground))
                
                Divider()
                Spacer()
                
                VStack(spacing: 12) {
                    Text("Оберіть шаблон")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(viewStore.templates) { template in
                                TemplateItemView(
                                    template: template,
                                    isSelected: viewStore.selectedTemplateID == template.id
                                )
                                .onTapGesture {
                                    viewStore.send(.templateSelected(template))
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 150)
                    
                    Button {
                        viewStore.send(.doneButtonTapped)
                    } label: {
                        Text("Готово")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewStore.selectedTemplateID != nil ? Color.accentColor : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .contentShape(Rectangle())
                    .padding(.horizontal)
                    .padding(.bottom)
                    .disabled(viewStore.selectedTemplateID == nil)
                }
                .background(Color(.systemBackground))
            }
            .onAppear {
                viewStore.send(.onAppear)
            }
            .navigationTitle("Обрати шаблон")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    @ViewBuilder
    func templateView(forTemplate template: Template, viewStore: ViewStore<TemplateSelectionFeature.State, TemplateSelectionFeature.Action>, image: UIImage) -> some View {
        let campaign = viewStore.campaign
        let (purpose, goal) = (campaign.purpose, campaign.target?.formattedAmount.appendingCurrency ?? "")
        
        switch (template.gradient, template.imagePlacement) {
        case (.linearPurple, .topCenter):
            PurpleGradientTemplateView(purpose: purpose, goal: goal, viewProvider: {
                imageView(viewStore: viewStore, image: image)
            })
        case (.linearGreen, .topToBottomTrailing):
            GreenGradientTemplateView(purpose: purpose, goal: goal, viewProvider: {
                imageView(viewStore: viewStore, image: image)
            })
        case (.angularYellowBlue, .trailing):
            YellowBlueGradientTemplateView(purpose: purpose, goal: goal, viewProvider: {
                imageView(viewStore: viewStore, image: image)
            })
        case (.linearSilverBlue, .trailingToEdge):
            SilverBlueTemplateView(purpose: purpose, goal: goal, viewProvider: {
                imageView(viewStore: viewStore, image: image)
            })
        case (.radialRedBlack, .topToEdge):
            RedBlackGradientTemplateView(purpose: purpose, goal: goal, viewProvider: {
                imageView(viewStore: viewStore, image: image)
            })
        default: EmptyView()
        }
    }
    
    private func imageView(viewStore: ViewStore<TemplateSelectionFeature.State, TemplateSelectionFeature.Action>, image: UIImage) -> some View {
        GeometryReader { geometry in
            let initialOffset = viewStore.campaign.image?.offset ?? .zero
            let initialScale = viewStore.campaign.image?.scale ?? 1.0
            
            ImageTransformView(
                image: image,
                initialOffset: initialOffset,
                initialScale: initialScale
            ) { newOffset, newScale in
                viewStore.send(.onImageRepositionFinished(newScale, newOffset))
            }
        }
    }
    
    struct ImageTransformView: View {
        let image: UIImage
        let onTransformEnd: (CGSize, CGFloat) -> Void
        
        @State private var offset: CGSize
        @State private var scale: CGFloat
        
        init(image: UIImage, initialOffset: CGSize, initialScale: CGFloat, onTransformEnd: @escaping (CGSize, CGFloat) -> Void) {
            self.image = image
            self.onTransformEnd = onTransformEnd
            _offset = State(initialValue: initialOffset)
            _scale = State(initialValue: initialScale)
        }
        
        var body: some View {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            offset = gesture.translation
                        }
                        .onEnded { _ in
                            onTransformEnd(offset, scale)
                        }
                )
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            scale = value
                        }
                        .onEnded { value in
                            scale = max(1.0, value)
                            onTransformEnd(offset, scale)
                        }
                )
        }
    }
}

struct TemplateItemView: View {
    let template: Template
    let isSelected: Bool
    
    var body: some View {
        VStack {
            Image("template_\(template.name)")
                .resizable()
                .frame(width: 120, height: 130)
            Text(template.name)
                .fontWeight(.bold)
        }
        .background {
            if isSelected {
                Color.blue.opacity(0.2)
            }
        }
    }
}

#Preview {
    NavigationStack {
        TemplateSelectionView(
            store: Store(
                initialState: TemplateSelectionFeature.State(
                    campaign: .mock1
                ),
                reducer: {
                    TemplateSelectionFeature()
                        ._printChanges()
                }
            )
        )
    }
} 

fileprivate extension Template {
    static let list: IdentifiedArrayOf<Template> = [
        .init(name: "1", gradient: .linearPurple, imagePlacement: .topCenter),
        .init(name: "2", gradient: .linearGreen, imagePlacement: .topToBottomTrailing),
        .init(name: "3", gradient: .angularYellowBlue, imagePlacement: .trailing),
        .init(name: "4", gradient: .linearSilverBlue, imagePlacement: .trailingToEdge),
        .init(name: "5", gradient: .radialRedBlack, imagePlacement: .topToEdge)
    ]
}

extension String {
    var appendingCurrency: String {
        return self + " грн."
    }
}
