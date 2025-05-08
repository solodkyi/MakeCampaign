import SwiftUI
import ComposableArchitecture

struct TemplateSelectionFeature: Reducer {
    struct State: Equatable {
        let photoURL: URL
        var selectedTemplateID: Template.ID?
        var templates: IdentifiedArrayOf<Template> = Template.mockTemplates
        
        var selectedTemplate: Template? {
            selectedTemplateID.flatMap { id in templates[id: id] }
        }
        
        init(photoURL: URL, templates: IdentifiedArrayOf<Template> = Template.mockTemplates, selectedTemplateID: Template.ID? = nil) {
            self.photoURL = photoURL
            self.templates = templates
            self.selectedTemplateID = selectedTemplateID
        }
    }
    
    enum Action: Equatable {
        case onAppear
        case templateSelected(Template.ID)
        case delegate(DelegateAction)
        case doneButtonTapped
        
        enum DelegateAction: Equatable {
            case templateSelected(Template.ID)
        }
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .none
                
            case let .templateSelected(templateID):
                state.selectedTemplateID = templateID
                return .none
                
            case .doneButtonTapped:
                if let templateID = state.selectedTemplateID {
                    return .send(.delegate(.templateSelected(templateID)))
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
                // Preview area
                ZStack {
                    if let uiImage = UIImage(contentsOfFile: viewStore.photoURL.path) {
                        if let selectedTemplate = viewStore.selectedTemplate {
                            // Show image with template preview applied
                            TemplatePreviewView(
                                image: uiImage,
                                template: selectedTemplate
                            )
                        } else {
                            // Show just the image
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                        }
                    } else {
                        Text("Unable to load image")
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
                .background(Color(.systemGroupedBackground))
                
                Divider()
                
                // Template selection area
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
                                    viewStore.send(.templateSelected(template.id))
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
        ZStack {
            // Base image
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
            
            // Apply template layout
            Group {
                switch template.layout {
                case .bottom:
                    VStack {
                        Spacer()
                        TemplateTextArea(template: template)
                    }
                case .overlay:
                    TemplateTextArea(template: template)
                case .side:
                    HStack {
                        Spacer()
                        TemplateTextArea(template: template)
                            .frame(width: 120)
                    }
                case .minimal:
                    VStack {
                        Spacer()
                        HStack {
                            TemplateTextArea(template: template, isMinimal: true)
                            Spacer()
                        }
                        .padding(.horizontal, 8)
                        .padding(.bottom, 8)
                    }
                case .banner:
                    VStack {
                        TemplateTextArea(template: template, isBanner: true)
                            .frame(height: 40)
                        Spacer()
                    }
                }
            }
        }
        .cornerRadius(getCornerRadius())
    }
    
    private func getCornerRadius() -> CGFloat {
        switch template.cornerStyle {
        case .none:
            return 0
        case .rounded(let radius):
            return radius
        }
    }
}

struct TemplateTextArea: View {
    let template: Template
    var isMinimal: Bool = false
    var isBanner: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Назва збору")
                .font(template.font)
                .foregroundColor(template.textColor)
            
            if !isMinimal {
                Text("Ціль: 100,000 грн")
                    .font(.caption)
                    .foregroundColor(template.textColor.opacity(0.8))
                
                ProgressView(value: 0.65)
                    .progressViewStyle(LinearProgressViewStyle(tint: template.textColor))
                    .padding(.top, 2)
            }
        }
        .padding(isMinimal ? 8 : 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(template.backgroundColor)
    }
}

struct TemplateItemView: View {
    let template: Template
    let isSelected: Bool
    
    var body: some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(template.backgroundColor)
                    .frame(width: 100, height: 100)
                
                VStack(spacing: 4) {
                    Text("Text")
                        .font(.caption)
                        .foregroundColor(template.textColor)
                    
                    if template.layout != .minimal {
                        ProgressView(value: 0.5)
                            .progressViewStyle(LinearProgressViewStyle(tint: template.textColor))
                            .frame(width: 60)
                    }
                }
                .padding(8)
                .frame(width: 100, height: 100)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
            )
            
            Text(template.name)
                .font(.caption)
                .foregroundColor(.primary)
                .frame(width: 100)
                .lineLimit(1)
        }
    }
}

#Preview {
    NavigationStack {
        TemplateSelectionView(
            store: Store(
                initialState: TemplateSelectionFeature.State(
                    photoURL: URL(string: "file:///tmp/mock")!
                ),
                reducer: {
                    TemplateSelectionFeature()
                        ._printChanges()
                }
            )
        )
    }
} 
