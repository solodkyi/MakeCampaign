import SwiftUI
import ComposableArchitecture
import Dependencies

struct TemplateSelectionView: View {
    let store: StoreOf<TemplateSelectionFeature>

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.displayScale) private var displayScale
    @Environment(\.locale) private var locale
    @Dependency(\.campaignPosterPreviewAssetLoader) private var previewAssetLoader
    @Dependency(\.campaignPosterThumbnailClient) private var thumbnailClient
    @State private var previewAssetBuffer = CampaignPosterPreviewAssetBuffer()
    @State private var templateThumbnailBatch: CampaignPosterThumbnailBatch?
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                if let uiImage = currentPreviewAssets.photo {
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
                
                templateThumbnailStrip

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
        .task(id: posterAssetInput) {
            await preparePreviewAssets(for: posterAssetInput)
        }
        .navigationTitle("Обрати шаблон")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var templateThumbnailStrip: some View {
        let currentRequests = templateThumbnailRequests
        let refreshKeys = currentRequests.map(\.refreshKey)
        if let requests = templateThumbnailBatch?.retainedRequests(
            matching: currentRequests
        ) {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(requests, id: \.template.id) { request in
                        let template = request.template
                        TemplateItemView(
                            request: request,
                            isSelected: store.selectedTemplateID == template.id
                        )
                        .onTapGesture {
                            store.send(.templateSelected(template))
                        }
                        .accessibilityIdentifier(
                            "legacy-template-\(template.id)"
                        )
                        .accessibilityValue(
                            store.selectedTemplateID == template.id
                                ? "Вибрано"
                                : ""
                        )
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 150)
            .accessibilityIdentifier("legacy-template-thumbnail-strip")
        } else {
            ProgressView("Готуємо шаблони…")
                .frame(height: 150)
                .frame(maxWidth: .infinity)
                .task(id: refreshKeys) {
                    templateThumbnailBatch = nil
                    await thumbnailClient.prewarm(currentRequests)
                    guard !Task.isCancelled else { return }
                    templateThumbnailBatch = CampaignPosterThumbnailBatch(
                        requests: currentRequests
                    )
                }
        }
    }

    private var templateThumbnailRequests: [CampaignPosterThumbnailRequest] {
        store.templates.map { template in
            .templateSelection(
                campaign: store.campaign,
                template: template,
                pointSize: CGSize(width: 120, height: 120),
                displayScale: displayScale,
                colorScheme: colorScheme,
                locale: locale
            )
        }
    }

    private var posterAssetInput: CampaignPosterPreviewAssetInput {
        CampaignPosterPreviewAssetInput(
            photoData: store.campaign.image?.raw,
            qrPayload: nil
        )
    }

    private var currentPreviewAssets: CampaignPosterPreviewAssets {
        previewAssetBuffer.assets
    }

    private func preparePreviewAssets(
        for input: CampaignPosterPreviewAssetInput
    ) async {
        previewAssetBuffer.beginLoading(input)
        do {
            let assets = try await previewAssetLoader.load(input)
            try Task.checkCancellation()
            previewAssetBuffer.commit(assets, for: input)
        } catch {
            guard !Task.isCancelled else { return }
        }
    }
}

struct TemplateItemView: View {
    let request: CampaignPosterThumbnailRequest
    let isSelected: Bool
    
    var body: some View {
        VStack {
            CampaignPosterThumbnail(request: request)
                .frame(width: 120, height: 120)
            Text(request.template.name)
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
                    campaign: Shared(value: Campaign.mock1)
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
        .init(name: "1", series: .b, gradient: .blueLinear, imagePlacement: .center),
        .init(name: "2", series: .b, gradient: .cyanMagentaRadial, imagePlacement: .squareTrailing),
        .init(name: "3", series: .b, gradient: .linearPurple, imagePlacement: .topCenter),
        .init(name: "4", series: .b, gradient: .goldBlackLinear, imagePlacement: .hexagonTrailing),
        .init(name: "5", series: .b, gradient: .pinkAngular, imagePlacement: .topCenter),
        .init(name: "6", series: .b, gradient: .tealPurpleRadial, imagePlacement: .roundedTrailing),
        .init(name: "7", series: .b, gradient: .linearGreen, imagePlacement: .topToBottomTrailing),
        .init(name: "8", series: .b, gradient: .angularYellowBlue, imagePlacement: .trailing),
        .init(name: "9", series: .b, gradient: .linearSilverBlue, imagePlacement: .trailingToEdge),
        .init(name: "10", series: .b, gradient: .radialRedBlack, imagePlacement: .topToEdge),
        .init(name: "11", series: .b, gradient: .linearIndigoOrange, imagePlacement: .trailing),
        .init(name: "12", series: .b, gradient: .linearEmeraldBlack, imagePlacement: .hexagonTrailing),
        .init(name: "13", series: .b, gradient: .radialAquaPurple, imagePlacement: .squareTrailing),
        .init(name: "14", series: .b, gradient: .radialMintIndigo, imagePlacement: .roundedTrailing),
        .init(name: "15", series: .b, gradient: .linearCoralTeal, imagePlacement: .trailing),
        .init(name: "A1", series: .a, gradient: .blueLinear, imagePlacement: .center),
        .init(name: "A2", series: .a, gradient: .cyanMagentaRadial, imagePlacement: .squareTrailing),
        .init(name: "A3", series: .a, gradient: .linearPurple, imagePlacement: .topCenter),
        .init(name: "A4", series: .a, gradient: .goldBlackLinear, imagePlacement: .hexagonTrailing),
        .init(name: "A5", series: .a, gradient: .pinkAngular, imagePlacement: .topCenter)
    ]
}

extension String {
    var appendingCurrency: String {
        return self + " грн."
    }
}
