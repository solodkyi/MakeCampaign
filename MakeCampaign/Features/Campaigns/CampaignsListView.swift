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
                    onDelete: { campaignPendingDeletion = $0 }
                )
            }

            CreateCampaignButton {
                store.send(.createCampaignTapped)
            }
                .padding(.trailing, 22)
                .padding(.bottom, 26)
        }
        .task {
            store.send(.onViewInitialLoad)
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
    let onDelete: (Campaign) -> Void

    var body: some View {
        List {
            ForEach(campaigns) { campaign in
                CampaignRow(
                    campaign: campaign,
                    palette: palette,
                    jarPresentation: presentation(campaign)
                ) {
                    onEdit(campaign.id)
                }
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

private struct CampaignRow: View {
    let campaign: Campaign
    let palette: CampaignsPalette
    let jarPresentation: CampaignsFeature.JarPresentation
    let onEdit: () -> Void

    var body: some View {
        Button(action: onEdit) {
            HStack(spacing: 13) {
                CampaignThumbnail(campaign: campaign, palette: palette)

                VStack(alignment: .leading, spacing: 0) {
                    Text(campaign.purpose.isEmpty ? "Без назви" : campaign.purpose)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(palette.foreground)
                        .lineLimit(2)

                    Spacer(minLength: 8)
                    CampaignJarDetails(
                        campaign: campaign,
                        presentation: jarPresentation,
                        palette: palette
                    )
                }
                .padding(.vertical, 2)
            }
            .frame(minHeight: 126)
            .padding(11)
            .background(palette.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: palette.shadow, radius: 10, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("campaign-row-\(campaign.id.uuidString)")
        .accessibilityLabel(campaign.purpose.isEmpty ? "Без назви" : campaign.purpose)
        .accessibilityHint("Відкрити редактор збору")
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
        .accessibilityHidden(true)
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

private struct CampaignJarDetails: View {
    let campaign: Campaign
    let presentation: CampaignsFeature.JarPresentation
    let palette: CampaignsPalette

    var body: some View {
        switch presentation {
        case .loaded:
            if let details = campaign.jar?.details {
                Text(details.currencyFormatted)
                    .font(.system(size: 19, weight: .semibold, design: .monospaced))
                    .foregroundStyle(palette.accent)

                if let progress = campaign.progress {
                    CampaignProgress(progress: progress.fractionCompleted, palette: palette)
                }

                CampaignMeta(updatedAt: campaign.updatedAt, palette: palette)
            } else {
                UnavailableJarDetails(
                    message: "Не вдалося оновити",
                    updatedAt: campaign.updatedAt,
                    palette: palette
                )
            }
        case .noLink, .loading, .failed:
            UnavailableJarDetails(
                message: presentation.message,
                updatedAt: campaign.updatedAt,
                palette: palette
            )
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

private struct CampaignMeta: View {
    let updatedAt: Date
    let palette: CampaignsPalette

    var body: some View {
        HStack {
            Text(updatedAt, format: .relative(presentation: .named))
            Spacer()
            Text("оновлено")
        }
        .font(.system(size: 10, weight: .medium, design: .monospaced))
        .foregroundStyle(palette.muted)
    }
}

private struct UnavailableJarDetails: View {
    let message: String
    let updatedAt: Date
    let palette: CampaignsPalette

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(message)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(palette.muted)
            CampaignMeta(updatedAt: updatedAt, palette: palette)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct CampaignsEmptyState: View {
    let palette: CampaignsPalette
    let onCreate: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .fill(palette.paper)
                    .frame(width: 180, height: 180)
                Circle()
                    .trim(from: 0.08, to: 0.82)
                    .stroke(palette.progressTrack, style: .init(lineWidth: 14, lineCap: .round))
                    .overlay {
                        Circle()
                            .trim(from: 0.08, to: 0.32)
                            .stroke(palette.accent, style: .init(lineWidth: 14, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                    }
                    .frame(width: 84, height: 84)
                    .rotationEffect(.degrees(-90))
            }

            Text("Зборів ще немає")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(palette.foreground)
                .padding(.top, 26)

            Text("Створіть обкладинку та додайте дані збору.")
                .font(.system(size: 14))
                .multilineTextAlignment(.center)
                .foregroundStyle(palette.muted)
                .padding(.top, 10)
                .padding(.horizontal, 34)

            Button("Створити збір", action: onCreate)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(palette.accent, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .padding(.top, 24)
                .padding(.horizontal, 24)
                .accessibilityIdentifier("empty-create-campaign-button")

            Spacer()
        }
    }
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
    var muted: Color { colorScheme == .dark ? .white.opacity(0.56) : Color(red: 20 / 255, green: 20 / 255, blue: 19 / 255).opacity(0.55) }
    var accent: Color { Color(red: 224 / 255, green: 86 / 255, blue: 42 / 255) }
    var steel: Color { Color(red: 86 / 255, green: 105 / 255, blue: 120 / 255) }
    var progressTrack: Color { colorScheme == .dark ? .white.opacity(0.12) : Color.black.opacity(0.09) }
    var shadow: Color { colorScheme == .dark ? .black.opacity(0.35) : .black.opacity(0.05) }
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
                    onDelete: { _ in }
                )
            }

            CreateCampaignButton(action: {})
                .padding(.trailing, 22)
                .padding(.bottom, 26)
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

    static let allCampaigns = [noJar, refreshing, failed, loaded]

    static let presentations: [Campaign.ID: CampaignsFeature.JarPresentation] = [
        refreshing.id: .loading,
        failed.id: .failed,
        loaded.id: .loaded
    ]
}

#Preview("Empty") {
    CampaignsListPreviewScreen(campaigns: [], presentations: [:])
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
