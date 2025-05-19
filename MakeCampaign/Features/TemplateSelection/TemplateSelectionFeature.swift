import SwiftUI
import ComposableArchitecture

struct TemplateSelectionFeature: Reducer {
    struct State: Equatable {
        let campaign: Campaign
        var selectedTemplateID: Template.ID?
        var templates: IdentifiedArrayOf<Template> = Template.list
        
        var selectedTemplate: Template? {
            selectedTemplateID.flatMap { id in templates[id: id] }
        }
        
        init(campaign: Campaign, templates: IdentifiedArrayOf<Template> = Template.list, selectedTemplateID: Template.ID? = nil) {
            self.campaign = campaign
            self.templates = templates
            self.selectedTemplateID = selectedTemplateID
        }
    }
    
    @Dependency(\.dismiss) var dismiss
    
    enum Action: Equatable {
        case onAppear
        case templateSelected(Template)
        case delegate(Delegate)
        case doneButtonTapped
        
        enum Delegate: Equatable {
            case templateApplied(Template, forCampaign: Campaign.ID)
        }
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .none
                
            case let .templateSelected(template):
                state.selectedTemplateID = template.id
                return .none
            case .doneButtonTapped:
                if let templateID = state.selectedTemplateID,
                   let template = state.templates[id: templateID] {
                    return .run { [state] send in
                        await send(.delegate(.templateApplied(template, forCampaign: state.campaign.id)))
                        await self.dismiss()
                    }
                }
                return .none
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
                    if let imageData = viewStore.campaign.imageData,
                       let uiImage = UIImage(data: imageData) {
                        if let selectedTemplate = viewStore.selectedTemplate {
                            TemplatePreviewView(
                                image: uiImage,
                                template: selectedTemplate
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
                    
                    Button("Готово") {
                        viewStore.send(.doneButtonTapped)
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewStore.selectedTemplateID != nil ? Color.accentColor : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.bottom)
                    .disabled(viewStore.selectedTemplateID == nil)
                }
                .frame(height: 240)
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

struct TemplatePreviewView: View {
    let image: UIImage
    let template: Template
    
    var body: some View {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
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
        .init(name: "1"),
        .init(name: "2"),
        .init(name: "3"),
        .init(name: "4"),
        .init(name: "5"),
    ]
}
