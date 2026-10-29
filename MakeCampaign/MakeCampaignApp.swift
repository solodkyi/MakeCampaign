//
//  MakeCampaignApp.swift
//  MakeCampaign
//
//  Created by Andrii Solodkyi on 5/1/25.
//

import SwiftUI
import ComposableArchitecture

struct AppView: View {
    @Bindable var store: StoreOf<AppFeature>
    
    var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            CampaignsView(
                store: self.store.scope(
                    state: \.campaignsList,
                    action: \.campaignsList
                )
            )
            .navigationTitle("Збори")
        } destination: { store in
            switch store.case {
            case let .details(store):
                CampaignDetailsFormView(store: store)
            case let .editor(store):
                CampaignCreationView(store: store)
            }
        }
    }
}

extension URL {
    static let campaigns = Self.documentsDirectory.appending(component: "campaigns.json")
}

#Preview {
    AppView(store: .init(initialState: AppFeature.State(), reducer: {
        AppFeature()
            ._printChanges()
    }, withDependencies: {
        $0.defaultFileStorage = .inMemory
    } ))
}

@main
struct MakeCampaignApp: App {
    private let store: StoreOf<AppFeature>

    init() {
        if ProcessInfo.processInfo.isUITesting {
            store = withDependencies {
                $0.defaultFileStorage = .inMemory
                if ProcessInfo.processInfo.arguments.contains("UI_TESTING_SEEDED_LIST") {
                    $0.jarApiClient = .seededList
                }
            } operation: {
                Store(initialState: Self.uiTestState()) { AppFeature() }
            }
        } else {
            store = Store(initialState: AppFeature.State()) { AppFeature() }
        }
    }

    var body: some Scene {
        WindowGroup {
            AppView(store: store)
        }
    }

    /// Список, на якому видно кожен вигляд рядка: збір без банки, збір на
    /// півдорозі й зібраний. Суми банок приходять із `JarAPIClient.seededList`,
    /// тож тести не ходять у мережу. Кожен запис — власний шаблон і власна
    /// світлина, щоб список не виглядав як один і той самий плакат тричі.
    private static func seededListCampaigns() -> IdentifiedArrayOf<Campaign> {
        // Кожен збір веде та світлина, про яку він і зібраний: zbir1 — FPV-дрон
        // у руці, zbir2 — коробка «Мавіка», zbir3 — авто евакуації.
        //
        // Шаблон дібрано під форму світлини, бо `PosterPhoto` заповнює рамку, а
        // не вписується в неї: альбомний zbir2 стоїть у смузі на всю ширину, а
        // портретні zbir1 і zbir3 — у майже квадратній прорізі ваучера та в
        // широкій картці.
        //
        // Зсув добирає решту. Заповнена рамка тримається верху світлини, а не
        // її середини, тож без зсуву у вузьку смугу потрапляє те, що над
        // героєм: стіна над дроном, небо над автом. Кожне число тут — частка
        // висоти рамки, на яку світлину піднято, щоб у кадрі став сам герой.
        func template(named name: String) -> Template? {
            Template.list.first(where: { $0.name == name })
        }
        func image(_ resource: String, offsetY: CGFloat = 0) -> Campaign.Image? {
            Bundle.main.url(forResource: resource, withExtension: "png")
                .flatMap { try? Data(contentsOf: $0) }
                .map {
                    Campaign.Image(
                        raw: $0,
                        offset: CGSize(width: 0, height: offsetY),
                        // Одиничний вимір робить зсув часткою рамки, тож те саме
                        // число працює і в мініатюрі списку, і на повному плакаті.
                        referenceSize: CGSize(width: 1, height: 1)
                    )
                }
        }

        return [
            Campaign(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000044")!,
                image: image("zbir1", offsetY: -0.23),
                template: template(named: "7"),
                purpose: "FPV-дрони для 3 ОШБр",
                target: 20_000
            ),
            Campaign(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000045")!,
                image: image("zbir2", offsetY: -0.18),
                template: template(named: "10"),
                purpose: "Дрони для розвідки",
                target: 75_000,
                jar: .init(link: JarAPIClient.seededJar(kopecks: 4_650_000))
            ),
            Campaign(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000046")!,
                image: image("zbir3", offsetY: -0.72),
                template: template(named: "14"),
                purpose: "Авто для евакуації",
                target: 280_000,
                jar: .init(link: JarAPIClient.seededJar(kopecks: 28_000_000))
            ),
        ]
    }

    private static func uiTestState() -> AppFeature.State {
        var state = AppFeature.State()
        let arguments = ProcessInfo.processInfo.arguments
        let isPhotoOnlyEditor = arguments.contains("UI_TESTING_PHOTO_ONLY_EDITOR")
        let isSeededEditor = arguments.contains("UI_TESTING_SEEDED_EDITOR")
        let isPhotoProcessingEditor = arguments.contains("UI_TESTING_PHOTO_PROCESSING_EDITOR")
        if arguments.contains("UI_TESTING_SEEDED_LIST") {
            state.campaignsList.$campaigns.withLock { $0 = seededListCampaigns() }
            return state
        }
        guard isPhotoOnlyEditor || isSeededEditor,
              let imageURL = Bundle.main.url(forResource: "zbir1", withExtension: "png"),
              let imageData = try? Data(contentsOf: imageURL) else {
            return state
        }

        if isPhotoOnlyEditor {
            let campaign = Campaign(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000043")!,
                image: .init(raw: imageData),
                status: .draft
            )
            state.path.append(.editor(.init(
                campaign: campaign,
                campaigns: state.campaignsList.$campaigns,
                isNew: true
            )))
            return state
        }

        guard let template = Template.list.first else { return state }

        let campaign = Campaign(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000042")!,
            image: .init(raw: imageData),
            template: template,
            purpose: "FPV-дрони для 3 ОШБр",
            target: 20_000,
            jar: .init(
                link: URL(string: "https://send.monobank.ua/jar/2Kd9x")!,
                details: .init(jarAmount: 1_240_000, jarStatus: "ACTIVE")
            ),
            status: .draft,
            showsQRCode: true,
            shareCaption: "FPV-дрони для 3 ОШБр. Підтримайте збір."
        )
        var editorState = CampaignCreationFeature.State(
            campaign: campaign,
            campaigns: state.campaignsList.$campaigns,
            isNew: true
        )
        if isPhotoProcessingEditor {
            editorState.photoPhase = .processing
        }
        state.path.append(.editor(editorState))
        return state
    }
}

private extension JarAPIClient {
    /// Банки засіяного списку: сума в копійках записана прямо в посиланні, тож
    /// кожен рядок отримує передбачуване число без мережі.
    static func seededJar(kopecks: Int) -> URL {
        URL(string: "https://send.monobank.ua/jar/seeded-\(kopecks)")!
    }

    static let seededList = Self { url in
        guard let kopecks = url.lastPathComponent
            .split(separator: "-")
            .last
            .flatMap({ Int($0) }) else {
            throw URLError(.badURL)
        }
        return JarDetails(jarAmount: kopecks, jarStatus: "ACTIVE")
    }
}
