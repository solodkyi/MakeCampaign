import XCTest
import UIKit

@testable import MakeCampaign

@MainActor
final class CampaignRendererPerformanceTests: XCTestCase {
    func testWarmRenderBenchmark() async throws {
        guard ProcessInfo.processInfo.environment["CAMPAIGN_RENDERER_BENCHMARK"] == "1" else {
            throw XCTSkip("Set CAMPAIGN_RENDERER_BENCHMARK=1 to run renderer timing")
        }

        let source = UIGraphicsImageRenderer(
            size: CGSize(width: 1_200, height: 1_200)
        ).image { context in
            UIColor.orange.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1_200, height: 1_200))
        }
        let data = try XCTUnwrap(source.jpegData(compressionQuality: 0.9))
        let template = try XCTUnwrap(Template.list.first)
        let clock = ContinuousClock()

        for format in Campaign.PosterFormat.allCases {
            let campaign = Campaign(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                image: .init(raw: data),
                template: template,
                purpose: "Аптечки",
                target: 20_000,
                posterFormat: format
            )
            _ = try await CampaignRenderer.liveValue.render(campaign)

            var milliseconds: [Double] = []
            for _ in 0..<5 {
                let start = clock.now
                _ = try await CampaignRenderer.liveValue.render(campaign)
                let components = start.duration(to: clock.now).components
                milliseconds.append(
                    Double(components.seconds) * 1_000
                        + Double(components.attoseconds) / 1_000_000_000_000_000
                )
            }

            let sorted = milliseconds.sorted()
            print(
                "CampaignRenderer \(format.rawValue) "
                    + "median_ms=\(sorted[2]) samples=\(sorted)"
            )
        }
    }
}
