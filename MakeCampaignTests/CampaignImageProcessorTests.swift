import Foundation
import Testing
import UIKit

@testable import MakeCampaign

@Suite("Campaign image processor")
struct CampaignImageProcessorTests {
    @Test("Invalid data is rejected")
    func rejectsInvalidData() async {
        await #expect(throws: CampaignImageProcessor.ProcessingError.invalidImage) {
            _ = try await CampaignImageProcessor.liveValue.process(Data([0x00]))
        }
    }

    @Test("Oversized photos are bounded to the processor limit")
    func boundsOversizedPhoto() async throws {
        let source = UIGraphicsImageRenderer(
            size: CGSize(width: 2_500, height: 1_250)
        ).image { context in
            UIColor.orange.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 2_500, height: 1_250))
        }
        let input = try #require(source.pngData())

        let result = try await CampaignImageProcessor.liveValue.process(input)
        let image = try #require(UIImage(data: result))

        #expect(CampaignImageProcessor.maximumPixelDimension == 2_400)
        #expect(image.size == CGSize(width: 2_400, height: 1_200))
    }
}
