import SwiftUI
import ComposableArchitecture

struct TemplateSelectionView: View {
    let store: StoreOf<TemplateSelectionFeature>
    
    var body: some View {
        WithPerceptionTracking {
            VStack(spacing: 0) {
                ZStack {
                    if let imageData = store.campaign.image?.raw,
                       let uiImage = UIImage(data: imageData) {
                        if let selectedTemplate = store.selectedTemplate {
                            CampaignTemplateView(
                                campaign: store.campaign,
                                template: selectedTemplate,
                                image: uiImage,
                                onImageTransformEnd: { newScale, newOffset, containerSize in
                                    store.send(.onImageRepositionFinished(newScale, newOffset, containerSize))
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
                            ForEach(store.templates) { template in
                                TemplateItemView(
                                    campaign: store.campaign,
                                    template: template,
                                    isSelected: store.selectedTemplateID == template.id)
                                .onTapGesture {
                                    store.send(.templateSelected(template))
                                }
                                
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 150)
                    
                    Button {
                        store.send(.doneButtonTapped)
                    } label: {
                        Text("Готово")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(store.selectedTemplateID != nil ? Color.accentColor : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .contentShape(Rectangle())
                    .padding(.horizontal)
                    .padding(.bottom)
                    .disabled(store.selectedTemplateID == nil)
                }
                .background(Color(.systemBackground))
            }
            .onAppear {
                store.send(.onAppear)
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
