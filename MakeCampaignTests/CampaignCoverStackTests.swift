import Testing
import Foundation
@testable import MakeCampaign

@Suite("Empty-state cover stack")
struct CampaignCoverStackTests {

    // MARK: - Sample catalogue

    @Test("The catalogue holds enough samples for the stack to cycle")
    func catalogueHoldsEnoughSamples() {
        #expect(
            CampaignCoverShowcase.samples.count
                >= CampaignCoverStackLayout.minimumSampleCount
        )
    }

    @Test("Every sample resolves to a template that still exists")
    func everySampleResolvesToAnExistingTemplate() {
        for sample in CampaignCoverShowcase.samples {
            #expect(
                sample.template != nil,
                "Зразок «\(sample.purpose)» посилається на шаблон \(sample.templateID), якого немає в Template.list"
            )
        }
    }

    @Test("Samples repeat neither an identifier nor a template")
    func samplesAreDistinct() {
        let samples = CampaignCoverShowcase.samples
        #expect(Set(samples.map(\.id)).count == samples.count)
        #expect(Set(samples.map(\.templateID)).count == samples.count)
    }

    @Test("A sample builds a campaign from its own template and photo")
    func sampleBuildsCampaign() throws {
        let sample = try #require(CampaignCoverShowcase.samples.first)
        let photoData = Data([0x01, 0x02])

        let campaign = sample.campaign(photoData: photoData)

        #expect(campaign.id == sample.id)
        #expect(campaign.purpose == sample.purpose)
        #expect(campaign.target == sample.target)
        #expect(campaign.image?.raw == photoData)
        #expect(campaign.template == sample.template)
        #expect(campaign.posterFormat == .square)
        #expect(campaign.showsQRCode == false)
    }

    @Test("A sample without a photo still builds a campaign")
    func sampleBuildsCampaignWithoutPhoto() throws {
        let sample = try #require(CampaignCoverShowcase.samples.first)

        #expect(sample.campaign(photoData: nil).image == nil)
    }

    // MARK: - Depth

    @Test("The front sample sits at depth zero")
    func frontSampleSitsAtDepthZero() {
        #expect(
            CampaignCoverStackLayout.depth(of: 2, frontIndex: 2, count: 5) == 0
        )
    }

    @Test("Depth wraps around the catalogue behind the front sample")
    func depthWrapsAroundTheCatalogue() {
        let depths = (0..<5).map {
            CampaignCoverStackLayout.depth(of: $0, frontIndex: 3, count: 5)
        }

        #expect(depths == [2, 3, 4, 0, 1])
    }

    @Test("Every sample occupies a depth of its own")
    func depthsAreAPermutation() {
        for frontIndex in 0..<5 {
            let depths = (0..<5).map {
                CampaignCoverStackLayout.depth(of: $0, frontIndex: frontIndex, count: 5)
            }
            #expect(Set(depths) == Set(0..<5))
        }
    }

    // MARK: - Placement

    @Test("The stack shows exactly three cards")
    func onlyThreeCardsAreVisible() {
        let visible = (0..<5)
            .map { CampaignCoverStackLayout.placement(depth: $0, count: 5, side: 200) }
            .filter { $0.opacity > 0 }

        #expect(visible.count == CampaignCoverStackLayout.visibleDepth)
    }

    @Test("The front card stands upright at full size")
    func frontCardIsUprightAndFullSize() {
        let front = CampaignCoverStackLayout.placement(depth: 0, count: 5, side: 200)

        #expect(front.rotationDegrees == 0)
        #expect(front.scale == 1)
        #expect(front.opacity == 1)
        #expect(front.shadowRadius > 0)
    }

    @Test("The back cards fan out in opposite directions")
    func backCardsFanOutInOppositeDirections() {
        let right = CampaignCoverStackLayout.placement(depth: 1, count: 5, side: 200)
        let left = CampaignCoverStackLayout.placement(depth: 2, count: 5, side: 200)

        #expect(right.rotationDegrees > 0)
        #expect(left.rotationDegrees < 0)
        #expect(right.offset.width > 0)
        #expect(left.offset.width < 0)
        #expect(right.scale < 1)
        #expect(left.scale < 1)
    }

    @Test("The card leaving the front flies up and fades out")
    func leavingCardFliesUpAndFadesOut() {
        let leaving = CampaignCoverStackLayout.placement(depth: 4, count: 5, side: 200)

        #expect(leaving.opacity == 0)
        #expect(leaving.offset.height < 0)
        #expect(leaving.scale > 1)
    }

    @Test("The card leaving the front passes above the rest of the stack")
    func leavingCardPassesAboveTheStack() {
        let leaving = CampaignCoverStackLayout.zIndex(depth: 4, count: 5)
        let others = (0..<4).map { CampaignCoverStackLayout.zIndex(depth: $0, count: 5) }

        #expect(others.allSatisfy { leaving > $0 })
    }

    @Test("A nearer card covers a farther one")
    func nearerCardsCoverFartherOnes() {
        let front = CampaignCoverStackLayout.zIndex(depth: 0, count: 5)
        let middle = CampaignCoverStackLayout.zIndex(depth: 1, count: 5)
        let back = CampaignCoverStackLayout.zIndex(depth: 2, count: 5)

        #expect(front > middle)
        #expect(middle > back)
    }

    @Test("Placement scales with the card side")
    func placementScalesWithCardSide() {
        let small = CampaignCoverStackLayout.placement(depth: 1, count: 5, side: 100)
        let large = CampaignCoverStackLayout.placement(depth: 1, count: 5, side: 200)

        #expect(large.offset.width == small.offset.width * 2)
        #expect(large.offset.height == small.offset.height * 2)
        #expect(large.shadowRadius == small.shadowRadius * 2)
        #expect(large.rotationDegrees == small.rotationDegrees)
    }

    @Test("A catalogue too small to cycle keeps every card visible")
    func aTooSmallCatalogueKeepsEveryCard() {
        let placements = (0..<3).map {
            CampaignCoverStackLayout.placement(depth: $0, count: 3, side: 200)
        }

        #expect(placements.allSatisfy { $0.opacity == 1 })
    }
}
