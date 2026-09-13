import Foundation
import SwiftUI
import Testing
import UIKit

@testable import MakeCampaign

/// Кожен шаблон мусить намалюватись у кожному грошовому стані.
///
/// Стан «зібрано» та смужка поступу — це нові гілки в тридцяти окремих
/// композиціях, і зламана гілка не падає: `ImageRenderer` просто віддає
/// порожнечу, а стос показує заглушку замість обкладинки. Тому їх перевіряє
/// тест, а не око.
@MainActor
@Suite("Poster funding renders")
struct CampaignPosterFundingRenderTests {
    private static let photo: UIImage = {
        UIGraphicsImageRenderer(size: CGSize(width: 64, height: 64)).image { context in
            UIColor.systemTeal.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 64, height: 64))
        }
    }()

    private static let fundingStates: [(name: String, funding: CampaignPosterFunding)] = [
        ("ціль без банки", CampaignPosterFunding(
            goal: "250 000 грн.", collected: nil, fraction: nil, isFinished: false
        )),
        ("поступ", CampaignPosterFunding(
            goal: "250 000 грн.", collected: "162 500 грн.", fraction: 0.65, isFinished: false
        )),
        ("зібрано", CampaignPosterFunding(
            goal: "250 000 грн.", collected: "250 000 грн.", fraction: 1, isFinished: true
        )),
        ("зібрано без сум", CampaignPosterFunding(
            goal: nil, collected: nil, fraction: nil, isFinished: true
        )),
        ("порожньо", .none),
    ]

    /// Кожен шаблон із каталогу — плюс знятий із каталогу, бо збори, збережені
    /// на ньому, теж мають малюватись.
    private static var everyTemplate: [Template] {
        Template.list + [
            Template(
                name: "6",
                series: .b,
                gradient: .tealPurpleRadial,
                imagePlacement: .roundedTrailing
            )
        ]
    }

    @Test("Every template draws something in every funding state")
    func everyTemplateDrawsInEveryFundingState() throws {
        for template in Self.everyTemplate {
            for state in Self.fundingStates {
                let image = Self.render(template: template, funding: state.funding)

                let rendered = try #require(
                    image,
                    "Шаблон \(template.id) не намалювався у стані «\(state.name)»"
                )
                #expect(
                    rendered.size.width > 0 && rendered.size.height > 0,
                    "Шаблон \(template.id) дав порожнє полотно у стані «\(state.name)»"
                )
            }
        }
    }

    @Test("Every template says «Зібрано!» when the collection is closed")
    func everyTemplateAnnouncesTheFinishedState() throws {
        // Порівнюємо пікселі: підпис-вигук мусить змінити плакат, інакше
        // завершений збір нічим не відрізняється від того, що триває.
        for template in Self.everyTemplate where template.id != "b_tealPurpleRadial_roundedTrailing" {
            let collecting = try #require(
                Self.render(template: template, funding: Self.fundingStates[1].funding)?.pngData()
            )
            let finished = try #require(
                Self.render(template: template, funding: Self.fundingStates[2].funding)?.pngData()
            )

            #expect(
                collecting != finished,
                "Шаблон \(template.id) малює завершений збір так само, як той, що триває"
            )
        }
    }

    @Test("A progress bar changes the poster once a jar reports a sum")
    func everyTemplateShowsProgressOnceAJarReports() throws {
        for template in Self.everyTemplate where template.id != "b_tealPurpleRadial_roundedTrailing" {
            let goalOnly = try #require(
                Self.render(template: template, funding: Self.fundingStates[0].funding)?.pngData()
            )
            let withProgress = try #require(
                Self.render(template: template, funding: Self.fundingStates[1].funding)?.pngData()
            )

            #expect(
                goalOnly != withProgress,
                "Шаблон \(template.id) не показує поступ, коли банка вже щось зібрала"
            )
        }
    }

    private static func render(
        template: Template,
        funding: CampaignPosterFunding
    ) -> UIImage? {
        let renderer = ImageRenderer(
            content: CampaignTemplateArtworkProbe(
                template: template,
                funding: funding,
                photo: photo
            )
            .frame(width: 300, height: 300)
        )
        renderer.scale = 1
        renderer.isOpaque = false
        return renderer.uiImage
    }
}

/// Малює шаблон із наперед заданим грошовим станом, оминаючи `Campaign`:
/// тест перевіряє композицію, а не те, як стан до неї дістався.
private struct CampaignTemplateArtworkProbe: View {
    let template: Template
    let funding: CampaignPosterFunding
    let photo: UIImage

    var body: some View {
        CampaignTemplateArtwork(
            campaign: campaign,
            template: template
        ) {
            Image(uiImage: photo)
                .resizable()
                .scaledToFill()
        }
    }

    /// `CampaignTemplateArtwork` бере суми зі збору, тож стан треба виразити
    /// саме через нього.
    private var campaign: Campaign {
        Campaign(
            id: UUID(uuidString: "00000000-0000-0000-0000-0000000000BB")!,
            purpose: "Збір на пікап для 160-ї ОМБр",
            target: funding.goal == nil ? nil : 250_000,
            jar: funding.fraction.map { fraction in
                Campaign.JarInfo(
                    link: URL(string: "https://send.monobank.ua/jar/probe")!,
                    details: JarDetails(
                        jarAmount: Int(250_000 * fraction * 100),
                        jarStatus: "ACTIVE"
                    )
                )
            },
            isClosedByAuthor: funding.isFinished
        )
    }
}
