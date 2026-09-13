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
    /// Зібране. Є там, де зразок має показати поступ або завершення; без нього
    /// обкладинка показує саму ціль, як щойно створений збір.
    let collected: Double?
    let isClosedByAuthor: Bool

    init(
        id: UUID,
        templateID: Template.ID,
        photoResource: String,
        purpose: String,
        target: Double,
        collected: Double? = nil,
        isClosedByAuthor: Bool = false
    ) {
        self.id = id
        self.templateID = templateID
        self.photoResource = photoResource
        self.purpose = purpose
        self.target = target
        self.collected = collected
        self.isClosedByAuthor = isClosedByAuthor
    }

    var template: Template? {
        Template.list[id: templateID]
    }

    func campaign(photoData: Data?) -> Campaign {
        Campaign(
            id: id,
            image: photoData.map { Campaign.Image(raw: $0) },
            template: template,
            purpose: purpose,
            target: target,
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
    static let samples: [CampaignCoverSample] = [
        CampaignCoverSample(
            id: UUID(uuidString: "A0000000-0000-0000-0000-000000000001")!,
            templateID: "b_blueLinear_center",
            photoResource: "zbir2",
            purpose: "Машина розмінування ZMIY",
            target: 2_000_000,
            collected: 1_240_000
        ),
        CampaignCoverSample(
            id: UUID(uuidString: "A0000000-0000-0000-0000-000000000002")!,
            templateID: "b_cyanMagentaRadial_squareTrailing",
            photoResource: "zbir3",
            purpose: "Аптечки для 3 ОШБр",
            target: 20_000,
            collected: 8_600
        ),
        CampaignCoverSample(
            id: UUID(uuidString: "A0000000-0000-0000-0000-000000000003")!,
            templateID: "a_goldBlackLinear_hexagonTrailing",
            photoResource: "zbir1",
            purpose: "Дрони для розвідки",
            target: 75_000
        ),
        CampaignCoverSample(
            id: UUID(uuidString: "A0000000-0000-0000-0000-000000000004")!,
            templateID: "b_linearGreen_topToBottomTrailing",
            photoResource: "zbir3",
            purpose: "Тепловізор для бригади",
            target: 60_000,
            collected: 60_000,
            isClosedByAuthor: true
        ),
        CampaignCoverSample(
            id: UUID(uuidString: "A0000000-0000-0000-0000-000000000005")!,
            templateID: "a_radialRedBlack_topToEdge",
            photoResource: "zbir1",
            purpose: "Генератор для бліндажа",
            target: 45_000,
            collected: 41_200
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
