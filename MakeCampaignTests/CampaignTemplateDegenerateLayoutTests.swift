import Dependencies
import SwiftUI
import Testing
import UIKit

@testable import MakeCampaign

/// Кожен шаблон малює себе всередині `GeometryReader`, а SwiftUI читає тіло
/// екрана ще до того, як дасть йому розмір: під час push-переходу
/// `UIHostingController.configurePreferredTransition(pushingFrom:)` бере
/// preferences із ще не розкладеного вигляду, і геометрія там — нулі.
///
/// Тож нульова сторона не є «неможливою»: це звичайний кадр із життя шаблону.
/// Шаблон, який ділить на власну сторону, у цьому кадрі падає — саме так
/// `linearGreen_topToBottomTrailing` завалював застосунок на переході.
@MainActor
@Suite("Campaign template degenerate layout")
struct CampaignTemplateDegenerateLayoutTests {
    @Test("Every template survives a zero-sized layout")
    func everyTemplateSurvivesZeroSide() throws {
        let campaign = try zeroLayoutCampaign()
        let raw = try #require(campaign.image?.raw)
        let photo = try #require(CampaignPosterAssetFactory.decodePhoto(raw))

        for template in Template.list {
            render(
                CampaignTemplateView(
                    campaign: campaign,
                    template: template,
                    image: photo
                ),
                side: 0
            )
        }
    }

    /// Та сама пастка з іншого боку: сторона, яку SwiftUI пропонує як
    /// «необмежену».
    @Test("Every template survives an unbounded layout")
    func everyTemplateSurvivesInfiniteSide() throws {
        let campaign = try zeroLayoutCampaign()
        let raw = try #require(campaign.image?.raw)
        let photo = try #require(CampaignPosterAssetFactory.decodePhoto(raw))

        for template in Template.list {
            render(
                CampaignTemplateView(
                    campaign: campaign,
                    template: template,
                    image: photo
                ),
                side: .infinity
            )
        }
    }

    /// Малюємо заради самого проходу тіла: на нульовій стороні картинки не
    /// буде, і це нормально. Падіння — не нормально, і саме його ловить тест.
    private func render<V: View>(_ view: V, side: CGFloat) {
        let renderer = ImageRenderer(
            content: view.frame(width: side, height: side)
        )
        renderer.scale = 1
        renderer.isOpaque = false

        _ = renderer.uiImage
    }

    private func zeroLayoutCampaign() throws -> Campaign {
        let photo = UIGraphicsImageRenderer(
            size: CGSize(width: 32, height: 32)
        ).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 32, height: 32))
        }

        return Campaign(
            id: UUID(uuidString: "00000000-0000-0000-0000-0000000000FF")!,
            image: .init(raw: try #require(photo.pngData())),
            template: Template.list.first,
            purpose: "Аптечки",
            target: 20_000,
            status: .draft,
            posterFormat: .square
        )
    }
}
