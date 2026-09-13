//
//  CampaignsListView.swift
//  MakeCampaign
//

import SwiftUI
import ComposableArchitecture

struct CampaignsView: View {
    @Bindable var store: StoreOf<CampaignsFeature>
    @Environment(\.colorScheme) private var colorScheme
    @State private var campaignPendingDeletion: Campaign?
    @State private var previewedCampaign: Campaign?

    var body: some View {
        let palette = CampaignsPalette(colorScheme: colorScheme)

        ZStack(alignment: .bottomTrailing) {
            palette.app.ignoresSafeArea()

            if store.visibleCampaigns.isEmpty {
                CampaignsEmptyState(
                    palette: palette,
                    onCreate: { store.send(.createCampaignTapped) }
                )
            } else {
                CampaignsList(
                    campaigns: store.visibleCampaigns,
                    palette: palette,
                    presentation: store.state.jarPresentation(for:),
                    onEdit: { store.send(.editCampaign($0)) },
                    onPreview: { previewedCampaign = $0 },
                    onDelete: { campaignPendingDeletion = $0 }
                )

                // Порожній стан має власну кнопку на всю ширину внизу екрана,
                // тож плаваюча кнопка там лише накрила б її.
                CreateCampaignButton {
                    store.send(.createCampaignTapped)
                }
                .padding(.trailing, 22)
                .padding(.bottom, 26)
            }
        }
        .task {
            store.send(.onViewInitialLoad)
        }
        .fullScreenCover(item: $previewedCampaign) { campaign in
            // Банка могла оновитися, поки постер відкритий, — тож малюємо
            // поточну версію збору, а не знімок із моменту натискання.
            CampaignPosterFullscreenPreview(
                campaign: store.campaigns[id: campaign.id] ?? campaign
            )
        }
        .alert(
            "Видалити збір?",
            isPresented: Binding(
                get: { campaignPendingDeletion != nil },
                set: { if !$0 { campaignPendingDeletion = nil } }
            ),
            presenting: campaignPendingDeletion
        ) { campaign in
            Button("Скасувати", role: .cancel) {
                campaignPendingDeletion = nil
            }
            Button("Видалити", role: .destructive) {
                store.send(.deleteCampaignConfirmed(campaign.id))
                campaignPendingDeletion = nil
            }
        } message: { _ in
            Text("Цю дію неможливо скасувати.")
        }
    }
}

private struct CampaignsList: View {
    let campaigns: [Campaign]
    let palette: CampaignsPalette
    let presentation: (Campaign) -> CampaignsFeature.JarPresentation
    let onEdit: (Campaign.ID) -> Void
    let onPreview: (Campaign) -> Void
    let onDelete: (Campaign) -> Void

    var body: some View {
        List {
            ForEach(campaigns) { campaign in
                CampaignRow(
                    campaign: campaign,
                    palette: palette,
                    jarPresentation: presentation(campaign),
                    onEdit: { onEdit(campaign.id) },
                    onPreview: { onPreview(campaign) }
                )
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button {
                        onDelete(campaign)
                    } label: {
                        Label("Видалити", systemImage: "trash")
                    }
                    .tint(.red)

                    Button {
                        onEdit(campaign.id)
                    } label: {
                        Label("Змінити", systemImage: "pencil")
                    }
                    .tint(palette.steel)
                }
                .listRowSeparator(.hidden)
                .listRowBackground(palette.app)
                .listRowInsets(.init(top: 0, leading: 20, bottom: 14, trailing: 20))
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

/// Рядок має дві дії: мініатюра розгортає постер на весь екран, решта картки
/// відкриває редактор. Тому це не одна кнопка, а дві поруч — вкладена кнопка
/// всередині іншої в SwiftUI натискань не отримує.
private struct CampaignRow: View {
    let campaign: Campaign
    let palette: CampaignsPalette
    let jarPresentation: CampaignsFeature.JarPresentation
    let onEdit: () -> Void
    let onPreview: () -> Void

    var body: some View {
        HStack(spacing: 13) {
            Button(action: onPreview) {
                CampaignThumbnail(campaign: campaign, palette: palette)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Переглянути постер")
            .accessibilityHint("Відкрити постер на весь екран")
            .accessibilityIdentifier("campaign-row-poster-\(campaign.id.uuidString)")

            Button(action: onEdit) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(palette.foreground)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Spacer(minLength: 8)

                    CampaignFundingSummary(
                        campaign: campaign,
                        presentation: jarPresentation,
                        palette: palette
                    )
                }
                .padding(.vertical, 2)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityHint("Відкрити редактор збору")
            .accessibilityIdentifier("campaign-row-\(campaign.id.uuidString)")
        }
        .frame(minHeight: 126)
        .padding(11)
        .background(palette.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        // Поля картки довкола обох кнопок теж ведуть у редактор, як і
        // раніше, коли весь рядок був однією кнопкою.
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .onTapGesture(perform: onEdit)
        .shadow(color: palette.shadow, radius: 10, x: 0, y: 2)
    }

    private var title: String {
        campaign.purpose.isEmpty ? "Без назви" : campaign.purpose
    }
}

private struct CampaignThumbnail: View {
    private static let size = CGSize(width: 104, height: 104)

    let campaign: Campaign
    let palette: CampaignsPalette

    @Dependency(\.campaignPosterPreviewAssetLoader) private var previewAssetLoader
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.displayScale) private var displayScale
    @Environment(\.locale) private var locale
    @State private var previewAssetBuffer = CampaignPosterPreviewAssetBuffer()

    var body: some View {
        ZStack {
            palette.field

            if let request = CampaignRowPosterThumbnailRequest.make(
                campaign: campaign,
                assets: previewAssetBuffer.assets,
                containerSize: Self.size,
                displayScale: displayScale,
                colorScheme: colorScheme,
                locale: locale
            ) {
                CampaignPosterThumbnail(request: request)
                    .frame(
                        width: request.pointSize.width,
                        height: request.pointSize.height
                    )
            } else {
                Image(systemName: "rectangle.portrait.on.rectangle.portrait")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(palette.muted)
            }
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .task(id: assetInput) {
            previewAssetBuffer.beginLoading(assetInput)
            do {
                let assets = try await previewAssetLoader.load(assetInput)
                try Task.checkCancellation()
                previewAssetBuffer.commit(assets, for: assetInput)
            } catch {
                guard !Task.isCancelled else { return }
            }
        }
    }

    private var assetInput: CampaignPosterPreviewAssetInput {
        CampaignPosterPreviewAssetInput(campaign: campaign)
    }
}

/// Гроші збору в рядку: скільки зібрано з якої цілі, а коли банки немає —
/// сама ціль. Рядок про оновлення має сенс лише там, де є що оновлювати,
/// тож збір без банки його не показує.
private struct CampaignFundingSummary: View {
    let campaign: Campaign
    let presentation: CampaignsFeature.JarPresentation
    let palette: CampaignsPalette

    var body: some View {
        switch presentation {
        case .loaded:
            if let collected = campaign.collected {
                VStack(alignment: .leading, spacing: 0) {
                    CollectedAmount(
                        collected: collected,
                        target: campaign.target,
                        palette: palette
                    )

                    if let fraction = campaign.fundedFraction {
                        CampaignProgress(progress: fraction, palette: palette)
                    } else {
                        Spacer().frame(height: 8)
                    }

                    CampaignMeta(
                        status: status,
                        updatedAt: campaign.updatedAt,
                        palette: palette
                    )
                }
            } else {
                awaitingJar(message: CampaignsFeature.JarPresentation.failed.message)
            }
        case .loading, .failed:
            awaitingJar(message: presentation.message)
        case .noLink:
            if let target = campaign.target {
                TargetAmount(target: target, palette: palette)
            }
        }
    }

    /// Банку підключено, але сум із неї ще немає: показуємо ціль, стан
    /// банки й коли збір востаннє оновлювався.
    private func awaitingJar(message: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            if let target = campaign.target {
                TargetAmount(target: target, palette: palette)
            }

            Text(message)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(palette.muted)

            CampaignMeta(status: nil, updatedAt: campaign.updatedAt, palette: palette)
        }
    }

    private var status: CampaignMeta.Status? {
        if campaign.isFinished {
            return .finished
        }
        return campaign.fundedFraction.map { .percent(Int(($0 * 100).rounded(.down))) }
    }
}

/// Зібране великим моноширинним, ціль — дрібно поруч, як у дизайні:
/// «1 240 000 / 2 000 000 ₴».
private struct CollectedAmount: View {
    let collected: Double
    let target: Double?
    let palette: CampaignsPalette

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Text(target == nil ? collected.formattedAmount.appendingCurrency : collected.formattedAmount)
                .font(.system(size: 19, weight: .semibold, design: .monospaced))
                .foregroundStyle(palette.foreground)

            if let target {
                Text("/ \(target.formattedAmount.appendingCurrency)")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(palette.muted)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
    }
}

/// Ціль без банки — єдина сума, яку збір знає, тож вона й стоїть великою.
private struct TargetAmount: View {
    let target: Double
    let palette: CampaignsPalette

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Ціль")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .tracking(1)
                .textCase(.uppercase)
                .foregroundStyle(palette.muted)

            Text(target.formattedAmount.appendingCurrency)
                .font(.system(size: 19, weight: .semibold, design: .monospaced))
                .foregroundStyle(palette.foreground)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }
}

private struct CampaignProgress: View {
    let progress: Double
    let palette: CampaignsPalette

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    var body: some View {
        GeometryReader { proxy in
            Capsule()
                .fill(palette.progressTrack)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(palette.accent)
                        .frame(width: proxy.size.width * clampedProgress)
                }
        }
        .frame(height: 5)
        .padding(.top, 9)
        .padding(.bottom, 7)
    }
}

/// Нижній рядок картки: ліворуч — де збір зараз, праворуч — коли банка
/// востаннє відповідала.
private struct CampaignMeta: View {
    enum Status {
        case percent(Int)
        case finished
    }

    let status: Status?
    let updatedAt: Date
    let palette: CampaignsPalette

    var body: some View {
        HStack(spacing: 8) {
            switch status {
            case let .percent(value):
                Text("\(value)%")
                    .foregroundStyle(palette.muted)
            case .finished:
                Text(CampaignPosterFunding.finishedLabel)
                    .foregroundStyle(palette.accent)
            case nil:
                EmptyView()
            }

            Spacer(minLength: 0)

            Text(verbatim: "оновлено \(updatedAt.formatted(Self.relativeDate))")
                .foregroundStyle(palette.muted)
                .lineLimit(1)
        }
        .font(.system(size: 10, weight: .medium, design: .monospaced))
    }

    /// Застосунок говорить українською, тож і «коли» — українською: інакше в
    /// англомовній системі рядок розпадається на «оновлено 5 minutes ago».
    /// Рядок форматується заздалегідь, бо формат усередині `Text` SwiftUI
    /// перекладає мовою середовища, хоч би яку мову йому задали.
    private static let relativeDate = Date.RelativeFormatStyle(presentation: .named)
        .locale(Locale(identifier: "uk_UA"))
}

/// Порожній стан продає результат: замість іконки застосунку — стос
/// справжніх обкладинок, які перебирають себе самі.
private struct CampaignsEmptyState: View {
    private static let coverSide: CGFloat = 200
    private static let advanceInterval = Duration.seconds(2.6)

    let palette: CampaignsPalette
    let onCreate: () -> Void

    @Dependency(\.campaignPosterPreviewAssetLoader) private var previewAssetLoader
    @Dependency(\.campaignPosterThumbnailClient) private var thumbnailClient
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.displayScale) private var displayScale
    @Environment(\.locale) private var locale
    @State private var covers: [CampaignCoverSample.ID: UIImage] = [:]
    @State private var frontIndex = 0

    private var samples: [CampaignCoverSample] { CampaignCoverShowcase.samples }

    /// Автоперебір вимкнено там, де рух заважає: у налаштуваннях доступності
    /// та під UI-тестами, для яких нескінченна анімація — це екран, що ніколи
    /// не стає idle.
    private var autoAdvances: Bool {
        !reduceMotion
            && !ProcessInfo.processInfo.isUITesting
            && samples.count >= CampaignCoverStackLayout.minimumSampleCount
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            CampaignCoverStack(
                samples: samples,
                covers: covers,
                frontIndex: frontIndex,
                side: Self.coverSide
            )
            .contentShape(Rectangle())
            .onTapGesture(perform: advance)

            Text("Збір починається з обкладинки")
                .font(.system(size: 22, weight: .heavy))
                .multilineTextAlignment(.center)
                .foregroundStyle(palette.foreground)
                .padding(.top, 26)

            Text("Фото, сума й посилання на банку — в одній картинці, готовій до сторіс і чатів.")
                .font(.system(size: 14))
                .multilineTextAlignment(.center)
                .foregroundStyle(palette.muted)
                .padding(.top, 10)

            Spacer(minLength: 0)

            Button(action: onCreate) {
                Label("Створити збір", systemImage: "plus")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(palette.invertedForeground)
                    .frame(maxWidth: .infinity, minHeight: 56)
            }
            .buttonStyle(.plain)
            .background(
                palette.foreground,
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .shadow(color: palette.raisedShadow, radius: 26, x: 0, y: 10)
            .accessibilityIdentifier("empty-create-campaign-button")
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 30)
        .task(id: coverRenderKey) {
            covers = await CampaignCoverRenderer.covers(
                for: samples,
                side: Self.coverSide,
                displayScale: displayScale,
                colorScheme: colorScheme,
                locale: locale,
                assetLoader: previewAssetLoader,
                thumbnailClient: thumbnailClient
            )
        }
        .task(id: autoAdvances) {
            guard autoAdvances else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: Self.advanceInterval)
                guard !Task.isCancelled else { return }
                advance()
            }
        }
    }

    private func advance() {
        guard !samples.isEmpty else { return }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.82)) {
            frontIndex = (frontIndex + 1) % samples.count
        }
    }

    private var coverRenderKey: CampaignCoverRenderKey {
        CampaignCoverRenderKey(
            displayScale: displayScale,
            usesDarkColorScheme: colorScheme == .dark,
            localeIdentifier: locale.identifier
        )
    }
}

private struct CampaignCoverRenderKey: Equatable {
    let displayScale: CGFloat
    let usesDarkColorScheme: Bool
    let localeIdentifier: String
}

private struct CreateCampaignButton: View {
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 26, weight: .medium))
                .frame(width: 58, height: 58)
        }
        .foregroundStyle(colorScheme == .dark ? Color.campaignFabDarkForeground : Color.campaignFabForeground)
        .background(
            colorScheme == .dark ? Color.campaignFabDarkBackground : Color.campaignFabBackground,
            in: RoundedRectangle(cornerRadius: 19, style: .continuous)
        )
        .shadow(color: .black.opacity(0.22), radius: 13, x: 0, y: 7)
        .accessibilityLabel("Створити збір")
        .accessibilityIdentifier("create-campaign-button")
    }
}

private struct CampaignsPalette {
    let colorScheme: ColorScheme

    var app: Color { colorScheme == .dark ? Color(red: 13 / 255, green: 13 / 255, blue: 12 / 255) : Color(red: 250 / 255, green: 249 / 255, blue: 247 / 255) }
    var surface: Color { colorScheme == .dark ? Color(red: 26 / 255, green: 26 / 255, blue: 24 / 255) : .white }
    var field: Color { colorScheme == .dark ? Color(red: 26 / 255, green: 26 / 255, blue: 24 / 255) : Color(red: 245 / 255, green: 243 / 255, blue: 239 / 255) }
    var paper: Color { colorScheme == .dark ? Color(red: 23 / 255, green: 23 / 255, blue: 22 / 255) : Color(red: 245 / 255, green: 243 / 255, blue: 239 / 255) }
    var foreground: Color { colorScheme == .dark ? .white.opacity(0.94) : Color(red: 20 / 255, green: 20 / 255, blue: 19 / 255) }
    var invertedForeground: Color { colorScheme == .dark ? Color(red: 20 / 255, green: 20 / 255, blue: 19 / 255) : .white }
    var muted: Color { colorScheme == .dark ? .white.opacity(0.56) : Color(red: 20 / 255, green: 20 / 255, blue: 19 / 255).opacity(0.55) }
    var accent: Color { Color(red: 224 / 255, green: 86 / 255, blue: 42 / 255) }
    var steel: Color { Color(red: 86 / 255, green: 105 / 255, blue: 120 / 255) }
    var progressTrack: Color { colorScheme == .dark ? .white.opacity(0.12) : Color.black.opacity(0.09) }
    var shadow: Color { colorScheme == .dark ? .black.opacity(0.35) : .black.opacity(0.05) }
    var raisedShadow: Color { colorScheme == .dark ? .black.opacity(0.5) : .black.opacity(0.22) }
}

private extension Color {
    static let campaignFabBackground = Color(red: 20 / 255, green: 20 / 255, blue: 19 / 255)
    static let campaignFabForeground = Color.white
    static let campaignFabDarkBackground = Color.white
    static let campaignFabDarkForeground = Color(red: 20 / 255, green: 20 / 255, blue: 19 / 255)
}

private struct CampaignsListPreviewScreen: View {
    let campaigns: [Campaign]
    let presentations: [Campaign.ID: CampaignsFeature.JarPresentation]

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let palette = CampaignsPalette(colorScheme: colorScheme)

        ZStack(alignment: .bottomTrailing) {
            palette.app.ignoresSafeArea()

            if campaigns.isEmpty {
                CampaignsEmptyState(palette: palette, onCreate: {})
            } else {
                CampaignsList(
                    campaigns: campaigns,
                    palette: palette,
                    presentation: { presentations[$0.id] ?? .noLink },
                    onEdit: { _ in },
                    onPreview: { _ in },
                    onDelete: { _ in }
                )

                CreateCampaignButton(action: {})
                    .padding(.trailing, 22)
                    .padding(.bottom, 26)
            }
        }
    }
}

private enum CampaignsListPreviewData {
    static let updatedAt = Date(timeIntervalSinceReferenceDate: 768_355_200)

    static let noJar = Campaign(
        id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
        purpose: "Допомога для підрозділу",
        target: 50_000,
        updatedAt: updatedAt
    )

    static let refreshing = Campaign(
        id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
        purpose: "Збір на автівку",
        target: 120_000,
        jar: .init(link: URL(string: "https://send.monobank.ua/jar/refreshing")!),
        updatedAt: updatedAt
    )

    static let failed = Campaign(
        id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
        purpose: "Тепловізор для бригади",
        target: 75_000,
        jar: .init(link: URL(string: "https://send.monobank.ua/jar/failed")!),
        updatedAt: updatedAt
    )

    static let loaded = Campaign(
        id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
        purpose: "Дрони для захисників",
        target: 100_000,
        jar: .init(
            link: URL(string: "https://send.monobank.ua/jar/loaded")!,
            details: .init(jarAmount: 67_500_00, jarStatus: "ACTIVE")
        ),
        updatedAt: updatedAt
    )

    static let finished = Campaign(
        id: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!,
        purpose: "Генератор для бліндажа",
        target: 45_000,
        jar: .init(
            link: URL(string: "https://send.monobank.ua/jar/finished")!,
            details: .init(jarAmount: 45_000_00, jarStatus: "ACTIVE")
        ),
        updatedAt: updatedAt
    )

    static let allCampaigns = [noJar, refreshing, failed, loaded, finished]

    static let presentations: [Campaign.ID: CampaignsFeature.JarPresentation] = [
        refreshing.id: .loading,
        failed.id: .failed,
        loaded.id: .loaded,
        finished.id: .loaded
    ]
}

// Порожній стан показує справжні обкладинки, тож прев'ю бере живі залежності
// — інакше стос лишився б із порожніх заглушок.
#Preview("Empty") {
    withDependencies {
        $0.campaignPosterPreviewAssetLoader = .liveValue
        $0.campaignPosterThumbnailClient = .liveValue
    } operation: {
        CampaignsListPreviewScreen(campaigns: [], presentations: [:])
    }
}

#Preview("Empty — dark") {
    withDependencies {
        $0.campaignPosterPreviewAssetLoader = .liveValue
        $0.campaignPosterThumbnailClient = .liveValue
    } operation: {
        CampaignsListPreviewScreen(campaigns: [], presentations: [:])
            .preferredColorScheme(.dark)
    }
}

#Preview("Jar not linked") {
    CampaignsListPreviewScreen(campaigns: [CampaignsListPreviewData.noJar], presentations: [:])
}

#Preview("Jar refreshing") {
    CampaignsListPreviewScreen(
        campaigns: [CampaignsListPreviewData.refreshing],
        presentations: [CampaignsListPreviewData.refreshing.id: .loading]
    )
}

#Preview("Jar refresh failed") {
    CampaignsListPreviewScreen(
        campaigns: [CampaignsListPreviewData.failed],
        presentations: [CampaignsListPreviewData.failed.id: .failed]
    )
}

#Preview("Jar progress") {
    CampaignsListPreviewScreen(
        campaigns: [CampaignsListPreviewData.loaded],
        presentations: [CampaignsListPreviewData.loaded.id: .loaded]
    )
}

#Preview("All states — dark") {
    CampaignsListPreviewScreen(
        campaigns: CampaignsListPreviewData.allCampaigns,
        presentations: CampaignsListPreviewData.presentations
    )
    .preferredColorScheme(.dark)
}
