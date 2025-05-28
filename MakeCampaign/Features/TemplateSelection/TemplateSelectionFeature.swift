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
        case onImageRepositionFinished(CGFloat, CGSize, CGSize)
        
        enum Delegate: Equatable {
            case templateApplied(Template, forCampaign: Campaign.ID)
            case imageRepositioned(CGFloat, CGSize, CGSize, forCampaign: Campaign.ID)
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
                
                return .send(.delegate(.imageRepositioned(1, .zero, .zero, forCampaign: state.campaign.id)))

            case .doneButtonTapped:
                if let templateID = state.selectedTemplateID,
                   let template = state.templates[id: templateID] {
                    return .run { [state] send in
                        await send(.delegate(.templateApplied(template, forCampaign: state.campaign.id)))
                        await self.dismiss()
                    }
                }
                return .none
            case let .onImageRepositionFinished(scale, offset, containerSize):
                state.campaign.imageScale = scale
                state.campaign.imageOffset = offset
                
                return .send(.delegate(.imageRepositioned(scale, offset, containerSize, forCampaign: state.campaign.id)))
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
                            CampaignTemplateView(
                                campaign: viewStore.campaign,
                                template: selectedTemplate,
                                image: uiImage,
                                onImageTransformEnd: { newScale, newOffset, containerSize in
                                    viewStore.send(.onImageRepositionFinished(newScale, newOffset, containerSize))
                                }
                            )
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
                .aspectRatio(1, contentMode: .fit)
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
                                    campaign: viewStore.campaign,
                                    template: template,
                                    isSelected: viewStore.selectedTemplateID == template.id)
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
}

struct TemplateItemView: View {
    let campaign: Campaign
    let template: Template
    let isSelected: Bool
    
    var body: some View {
        VStack {
            CampaignTemplateView(campaign: campaign, template: template)
                .frame(width: 120, height: 120)
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

extension Template {
    static let list: IdentifiedArrayOf<Template> = [
        .init(name: "1", gradient: .blueLinear, imagePlacement: .center),
        .init(name: "2", gradient: .cyanMagentaRadial, imagePlacement: .squareTrailing),
        .init(name: "3", gradient: .linearPurple, imagePlacement: .topCenter),
        .init(name: "4", gradient: .goldBlackLinear, imagePlacement: .hexagonTrailing),
        .init(name: "5", gradient: .pinkAngular, imagePlacement: .topCenter),
        .init(name: "6", gradient: .tealPurpleRadial, imagePlacement: .roundedTrailing),
        .init(name: "7", gradient: .linearGreen, imagePlacement: .topToBottomTrailing),
        .init(name: "8", gradient: .angularYellowBlue, imagePlacement: .trailing),
        .init(name: "9", gradient: .linearSilverBlue, imagePlacement: .trailingToEdge),
        .init(name: "10", gradient: .radialRedBlack, imagePlacement: .topToEdge)
    ]
}

extension String {
    var appendingCurrency: String {
        return self + " грн."
    }
}
