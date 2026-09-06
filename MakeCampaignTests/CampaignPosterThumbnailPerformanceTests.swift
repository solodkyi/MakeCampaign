import SwiftUI
import UIKit
import XCTest

@testable import MakeCampaign

@MainActor
final class CampaignPosterThumbnailPerformanceTests: XCTestCase {
    func testAllTemplateTilesBenchmark() async throws {
        guard ProcessInfo.processInfo.environment[
            "CAMPAIGN_THUMBNAIL_BENCHMARK"
        ] == "1" else {
            throw XCTSkip(
                "Set CAMPAIGN_THUMBNAIL_BENCHMARK=1 to run thumbnail timing"
            )
        }

        let campaign = try makeCampaign()
        let assets = CampaignPosterPreviewAssets(
            photo: campaign.image?.raw.flatMap(CampaignPosterAssetFactory.decodePhoto),
            qrCode: campaign.showsQRCode
                ? CampaignPosterAssetFactory.makeQRCode(campaign.jar?.link.absoluteString)
                : nil,
            signature: "baseline"
        )
        let clock = ContinuousClock()
        var coldSamples: [Double] = []
        var warmSamples: [Double] = []
        var initialVisibleSamples: [Double] = []

        for _ in 0..<5 {
            let store = CampaignPosterThumbnailStore()
            let start = clock.now
            var images: [UIImage] = []

            for template in Template.list {
                images.append(
                    try await store.image(
                        for: request(
                            campaign: campaign,
                            template: template,
                            assets: assets
                        )
                    )
                )
            }

            XCTAssertEqual(images.count, Template.list.count)
            coldSamples.append(milliseconds(from: start, to: clock.now))

            let warmStart = clock.now
            for template in Template.list {
                _ = try await store.image(
                    for: request(
                        campaign: campaign,
                        template: template,
                        assets: assets
                    )
                )
            }
            warmSamples.append(milliseconds(from: warmStart, to: clock.now))

            let visibleStore = CampaignPosterThumbnailStore()
            let visibleStart = clock.now
            for template in Template.list.prefix(4) {
                _ = try await visibleStore.image(
                    for: request(
                        campaign: campaign,
                        template: template,
                        assets: assets
                    )
                )
            }
            initialVisibleSamples.append(
                milliseconds(from: visibleStart, to: clock.now)
            )
        }

        let summary = "Campaign thumbnails cached_cold_all_ms=\(coldSamples.sorted()) "
            + "cached_warm_all_ms=\(warmSamples.sorted()) "
            + "lazy_initial_4_ms=\(initialVisibleSamples.sorted())"
        print(summary)
        XCTContext.runActivity(named: summary) { _ in }
    }

    func testManualImageTransformBenchmark() throws {
        guard ProcessInfo.processInfo.environment[
            "CAMPAIGN_THUMBNAIL_BENCHMARK"
        ] == "1" else {
            throw XCTSkip(
                "Set CAMPAIGN_THUMBNAIL_BENCHMARK=1 to run transform timing"
            )
        }

        let image = try makeSourceImage()
        let rasterized = try transformSamples(image: image, rasterizes: true)
        let plain = try transformSamples(image: image, rasterizes: false)
        let summary = "Campaign image transform drawing_group_60_frames_ms=\(rasterized) "
            + "plain_60_frames_ms=\(plain)"
        print(summary)
        XCTContext.runActivity(named: summary) { _ in }
    }

    private func request(
        campaign: Campaign,
        template: Template,
        assets: CampaignPosterPreviewAssets
    ) -> CampaignPosterThumbnailRequest {
        CampaignPosterThumbnailRequest(
            campaign: campaign,
            template: template,
            composition: .poster,
            assets: assets,
            pointSize: CGSize(width: 84, height: 84),
            displayScale: 3,
            colorScheme: .light,
            locale: Locale(identifier: "uk_UA")
        )
    }

    private func makeCampaign() throws -> Campaign {
        let source = try makeSourceImage()

        return Campaign(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            image: .init(
                raw: try XCTUnwrap(source.pngData()),
                offset: CGSize(width: 13, height: -9),
                scale: 1.25,
                referenceSize: CGSize(width: 240, height: 240),
                contentMode: .fill
            ),
            template: try XCTUnwrap(Template.list.first),
            purpose: "Аптечки для підрозділу",
            target: 20_000,
            jar: .init(link: URL(string: "https://send.monobank.ua/jar/example")!),
            status: .draft,
            posterFormat: .square,
            showsQRCode: true
        )
    }

    private func makeSourceImage() throws -> UIImage {
        if let url = Bundle.main.url(forResource: "zbir1", withExtension: "png"),
           let data = try? Data(contentsOf: url),
           let image = UIImage(data: data) {
            return image
        }

        return UIGraphicsImageRenderer(
            size: CGSize(width: 1_122, height: 1_200)
        ).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 561, height: 600))
            UIColor.green.setFill()
            context.fill(CGRect(x: 561, y: 0, width: 561, height: 600))
            UIColor.blue.setFill()
            context.fill(CGRect(x: 0, y: 600, width: 561, height: 600))
            UIColor.yellow.setFill()
            context.fill(CGRect(x: 561, y: 600, width: 561, height: 600))
        }
    }

    private func transformSamples(
        image: UIImage,
        rasterizes: Bool
    ) throws -> Double {
        let clock = ContinuousClock()
        let start = clock.now
        for frame in 0..<60 {
            let renderer = ImageRenderer(
                content: CampaignImageTransformProbe(
                    image: image,
                    offset: CGFloat(frame),
                    rasterizes: rasterizes
                )
                .frame(width: 350, height: 350)
            )
            renderer.scale = 3
            _ = try XCTUnwrap(renderer.uiImage)
        }
        return milliseconds(from: start, to: clock.now)
    }

    private func milliseconds(
        from start: ContinuousClock.Instant,
        to end: ContinuousClock.Instant
    ) -> Double {
        let components = start.duration(to: end).components
        return Double(components.seconds) * 1_000
            + Double(components.attoseconds) / 1_000_000_000_000_000
    }
}

private struct CampaignImageTransformProbe: View {
    let image: UIImage
    let offset: CGFloat
    let rasterizes: Bool

    @ViewBuilder
    var body: some View {
        if rasterizes {
            content.drawingGroup()
        } else {
            content
        }
    }

    private var content: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .scaleEffect(1.25)
            .offset(x: offset, y: -9)
            .clipped()
    }
}
