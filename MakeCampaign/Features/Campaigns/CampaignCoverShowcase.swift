import Foundation
import SwiftUI
import UIKit

/// Зразок обкладинки, який показує порожній стан списку зборів.
///
/// Зразок не має власного дизайну: він посилається на шаблон із
/// `Template.list` за ідентифікатором, тож стос показує рівно те, що
/// застосунок уміє відрендерити насправді. Якщо шаблон зникне з каталогу,
/// зразок перестане розв'язуватись — і тест каталогу впаде замість того,
/// щоб порожній екран мовчки показав діру.
struct CampaignCoverSample: Identifiable, Equatable, Sendable {
    let id: UUID
    let templateID: Template.ID
    let photoResource: String
    let purpose: String
    let target: Double
    /// Власна ціль автора в чужій збірці. Є лише там, де зразок має показати
    /// допоміжну банку: тоді `target` — загальна ціль збірки, а обкладинка
    /// веде цим числом і додає під ним рядок «із загальної цілі».
    let personalTarget: Double?
    /// Зібране. Є там, де зразок має показати поступ або завершення; без нього
    /// обкладинка показує саму ціль, як щойно створений збір.
    let collected: Double?
    let isClosedByAuthor: Bool
    /// Наближення світлини в рамці шаблона — те саме, що автор робить щипком.
    /// Рамка заповнюється світлиною, а не вписує її, тож у круглій чи
    /// квадратній прорізі портретне фото стоїть задалеко: об'єкт тоне в тлі.
    let photoScale: CGFloat
    /// Зсув світлини часткою рамки: `0.1` — десята її ширини чи висоти.
    /// Частками, а не пунктами, бо та сама обкладинка малюється і в стос
    /// завширшки 200 пунктів, і на повний плакат у 1080 пікселів.
    let photoOffset: CGSize

    init(
        id: UUID,
        templateID: Template.ID,
        photoResource: String,
        purpose: String,
        target: Double,
        personalTarget: Double? = nil,
        collected: Double? = nil,
        isClosedByAuthor: Bool = false,
        photoScale: CGFloat = 1,
        photoOffset: CGSize = .zero
    ) {
        self.id = id
        self.templateID = templateID
        self.photoResource = photoResource
        self.purpose = purpose
        self.target = target
        self.personalTarget = personalTarget
        self.collected = collected
        self.isClosedByAuthor = isClosedByAuthor
        self.photoScale = photoScale
        self.photoOffset = photoOffset
    }

    var template: Template? {
        Template.list[id: templateID]
    }

    func campaign(photoData: Data?) -> Campaign {
        Campaign(
            id: id,
            image: photoData.map {
                Campaign.Image(
                    raw: $0,
                    offset: photoOffset,
                    scale: photoScale,
                    // Одиничний вимір робить зсув часткою рамки: обкладинка
                    // ділить його на цей вимір і множить на власний.
                    referenceSize: CGSize(width: 1, height: 1)
                )
            },
            template: template,
            purpose: purpose,
            target: target,
            isSupportingJar: personalTarget != nil,
            personalTarget: personalTarget,
            jar: collected.map { collected in
                Campaign.JarInfo(
                    link: Self.showcaseJar,
                    details: JarDetails(
                        jarAmount: Int((collected * 100).rounded()),
                        jarStatus: "ACTIVE"
                    )
                )
            },
            status: .draft,
            posterFormat: .square,
            isClosedByAuthor: isClosedByAuthor
        )
    }

    /// Банка зразка нікуди не веде — обкладинка її не друкує, а QR у стосі
    /// вимкнено. Посилання потрібне лише тому, що без нього сума з банки не
    /// має де жити.
    private static let showcaseJar = URL(string: "https://send.monobank.ua/jar/showcase")!
}

enum CampaignCoverShowcase {
    /// П'ять зразків: три видно у стосі, один чекає позаду, ще один відлітає.
    /// Кількість не випадкова — її вимагає `CampaignCoverStackLayout`.
    ///
    /// Світлин лише три, тож дві з них стос показує двічі. Порядок розводить
    /// повтори якнайдалі — у циклі з п'яти карток це відстань два, більшої не
    /// буває, — а повторам дістаються шаблони різних наборів, щоб та сама
    /// світлина читалась як інший збір, а не як збій.
    ///
    /// Рамка шаблона вирішує, що від світлини лишиться: `PosterPhoto` заповнює
    /// свою рамку, а не вписується в неї. Тому альбомний `zbir2` стоїть у
    /// єдиній широкій рамці — смузі на всю ширину, — а портретні `zbir1` і
    /// `zbir3` живуть у високих, квадратних і круглих.
    static let samples: [CampaignCoverSample] = [
        // Ваучер: висока рамка праворуч — портретний дрон стає на весь зріст.
        CampaignCoverSample(
            id: UUID(uuidString: "A0000000-0000-0000-0000-000000000001")!,
            templateID: "b_linearGreen_topToBottomTrailing",
            photoResource: "zbir1",
            purpose: "На FPV",
            target: 15_000
        ),
        // Допоміжна банка: веде власна ціль автора, під нею — загальна.
        CampaignCoverSample(
            id: UUID(uuidString: "A0000000-0000-0000-0000-000000000002")!,
            templateID: "a_angularYellowBlue_trailing",
            photoResource: "zbir3",
            purpose: "На авто евакуації",
            target: 100_000,
            personalTarget: 20_000,
            collected: 14_259.75
        ),
        // Єдина широка рамка стоса — і єдина альбомна світлина.
        CampaignCoverSample(
            id: UUID(uuidString: "A0000000-0000-0000-0000-000000000003")!,
            templateID: "a_radialRedBlack_topToEdge",
            photoResource: "zbir2",
            purpose: "На мавік",
            target: 75_000,
            collected: 3_226.7
        ),
        CampaignCoverSample(
            id: UUID(uuidString: "A0000000-0000-0000-0000-000000000004")!,
            templateID: "b_angularYellowBlue_trailing",
            photoResource: "zbir1",
            purpose: "Дрони для розвідки",
            target: 40_000,
            collected: 28_400,
            // Дрон висить у нижній третині кадру, а коло бере середину: без
            // наближення й підйому в проріз потрапляє сама стіна.
            photoScale: 1.3,
            photoOffset: CGSize(width: 0, height: -0.22)
        ),
        // Завершений збір: стос показує і те, чим збір закінчується.
        CampaignCoverSample(
            id: UUID(uuidString: "A0000000-0000-0000-0000-000000000005")!,
            templateID: "b_radialMintIndigo_roundedTrailing",
            photoResource: "zbir3",
            purpose: "Позашляховик для медиків",
            target: 90_000,
            collected: 90_000,
            isClosedByAuthor: true,
            // Широка рамка бере з портретного кадру смугу посередині — саме
            // небо над автівкою. Зсув униз опускає її на машину.
            photoScale: 1,
            photoOffset: CGSize(width: 0, height: -0.26)
        )
    ]

    /// Читання з бандла винесене з головного потоку: світлини важать мегабайти,
    /// а стос з'являється одразу після запуску.
    static func photoData(named resource: String) async -> Data? {
        await Task.detached(priority: .utility) {
            Bundle.main.url(forResource: resource, withExtension: "png")
                .flatMap { try? Data(contentsOf: $0) }
        }.value
    }
}

/// Растеризує зразки наперед, щоб анімований стос рухав готові зображення,
/// а не перемальовував шаблони на кожному кадрі.
@MainActor
enum CampaignCoverRenderer {
    static func covers(
        for samples: [CampaignCoverSample],
        side: CGFloat,
        displayScale: CGFloat,
        colorScheme: ColorScheme,
        locale: Locale,
        assetLoader: CampaignPosterPreviewAssetLoader,
        thumbnailClient: CampaignPosterThumbnailClient
    ) async -> [CampaignCoverSample.ID: UIImage] {
        var covers: [CampaignCoverSample.ID: UIImage] = [:]
        var photos: [String: Data?] = [:]

        for sample in samples {
            guard !Task.isCancelled else { return covers }
            guard let template = sample.template else { continue }

            let photoData: Data?
            if let cached = photos[sample.photoResource] {
                photoData = cached
            } else {
                photoData = await CampaignCoverShowcase.photoData(
                    named: sample.photoResource
                )
                photos[sample.photoResource] = photoData
            }

            let campaign = sample.campaign(photoData: photoData)
            guard let assets = try? await assetLoader.load(
                CampaignPosterPreviewAssetInput(campaign: campaign)
            ) else { continue }

            let request = CampaignPosterThumbnailRequest(
                campaign: campaign,
                template: template,
                composition: .poster,
                assets: assets,
                pointSize: CampaignPosterLayout.previewSize(
                    for: campaign.posterFormat,
                    in: CGSize(width: side, height: side)
                ),
                displayScale: displayScale,
                colorScheme: colorScheme,
                locale: locale
            )

            guard let cover = try? await thumbnailClient.image(request) else {
                continue
            }
            covers[sample.id] = cover
            await Task.yield()
        }

        return covers
    }
}
