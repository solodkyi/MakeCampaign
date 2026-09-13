import Foundation
import Testing

@testable import MakeCampaign

@Suite("Campaign funding state")
struct CampaignFundingTests {
    private static let jar = URL(string: "https://send.monobank.ua/jar/2Kd9x")!

    private func campaign(
        target: Double? = 20_000,
        collected: Double? = nil,
        jarStatus: String = "ACTIVE",
        closedByAuthor: Bool = false
    ) -> Campaign {
        Campaign(
            id: UUID(uuidString: "00000000-0000-0000-0000-0000000000AA")!,
            purpose: "Аптечки для 3 ОШБр",
            target: target,
            jar: collected.map {
                Campaign.JarInfo(
                    link: Self.jar,
                    details: JarDetails(
                        jarAmount: Int(($0 * 100).rounded()),
                        jarStatus: jarStatus
                    )
                )
            },
            isClosedByAuthor: closedByAuthor
        )
    }

    // MARK: - Collected and fraction

    @Test("A campaign with no jar knows nothing about what it collected")
    func noJarMeansNoCollectedAmount() {
        let campaign = campaign()

        #expect(campaign.collected == nil)
        #expect(campaign.fundedFraction == nil)
    }

    @Test("A campaign reports what its jar holds")
    func collectedComesFromTheJar() {
        #expect(campaign(collected: 8_600).collected == 8_600)
    }

    @Test("The funded fraction is collected over target")
    func fundedFractionDividesCollectedByTarget() throws {
        let fraction = try #require(
            campaign(target: 20_000, collected: 5_000).fundedFraction
        )

        #expect(abs(fraction - 0.25) < 0.0001)
    }

    @Test("A poster never draws a bar longer than its track")
    func fundedFractionIsClampedAtOne() {
        #expect(campaign(target: 20_000, collected: 50_000).fundedFraction == 1)
    }

    @Test("A goal of zero yields no fraction rather than a division by zero")
    func zeroTargetYieldsNoFraction() {
        #expect(campaign(target: 0, collected: 5_000).fundedFraction == nil)
    }

    @Test("Without a goal there is no fraction to draw")
    func noTargetYieldsNoFraction() {
        #expect(campaign(target: nil, collected: 5_000).fundedFraction == nil)
    }

    // MARK: - Finished

    @Test("A collection under way is not finished")
    func collectingCampaignIsNotFinished() {
        #expect(campaign(target: 20_000, collected: 8_600).isFinished == false)
    }

    @Test("Reaching the goal finishes the collection")
    func reachingTheTargetFinishesIt() {
        #expect(campaign(target: 20_000, collected: 20_000).isFinished)
        #expect(campaign(target: 20_000, collected: 21_000).isFinished)
    }

    @Test("A jar closed by the bank finishes the collection, goal or not")
    func aClosedJarFinishesIt() {
        let campaign = campaign(
            target: 20_000,
            collected: 3_000,
            jarStatus: "CLOSED"
        )

        #expect(campaign.isJarClosed)
        #expect(campaign.isFinished)
    }

    @Test("The author can finish a collection that met neither condition")
    func theAuthorCanFinishItByHand() {
        let campaign = campaign(
            target: 20_000,
            collected: 3_000,
            closedByAuthor: true
        )

        #expect(campaign.hasReachedTarget == false)
        #expect(campaign.isJarClosed == false)
        #expect(campaign.isFinished)
    }

    @Test("A campaign with no jar at all is finished only by its author")
    func aCampaignWithoutAJarIsFinishedOnlyByHand() {
        #expect(campaign().isFinished == false)
        #expect(campaign(closedByAuthor: true).isFinished)
    }

    // MARK: - Persistence

    @Test("The author's decision survives a save and a load")
    func closedByAuthorRoundTrips() throws {
        let original = campaign(closedByAuthor: true)

        let decoded = try JSONDecoder().decode(
            Campaign.self,
            from: JSONEncoder().encode(original)
        )

        #expect(decoded.isClosedByAuthor)
    }

    @Test("A campaign saved before the author could close one decodes as open")
    func legacyCampaignDecodesAsOpen() throws {
        var fields = try #require(
            try JSONSerialization.jsonObject(
                with: JSONEncoder().encode(campaign(closedByAuthor: true))
            ) as? [String: Any]
        )
        fields.removeValue(forKey: "isClosedByAuthor")

        let decoded = try JSONDecoder().decode(
            Campaign.self,
            from: JSONSerialization.data(withJSONObject: fields)
        )

        #expect(decoded.isClosedByAuthor == false)
    }

    // MARK: - What the poster is handed

    @Test("The poster is handed the goal, the collected sum and the fraction")
    func posterFundingCarriesEveryFigure() throws {
        let funding = CampaignPosterFunding(
            campaign: campaign(target: 20_000, collected: 5_000)
        )

        #expect(funding.goal == 20_000.formattedAmount.appendingCurrency)
        #expect(funding.collected == 5_000.formattedAmount.appendingCurrency)
        #expect(abs(try #require(funding.fraction) - 0.25) < 0.0001)
        #expect(funding.isFinished == false)
    }

    @Test("A poster with no jar behind it is handed only the goal")
    func posterFundingWithoutAJarCarriesOnlyTheGoal() {
        let funding = CampaignPosterFunding(campaign: campaign())

        #expect(funding.goal != nil)
        #expect(funding.collected == nil)
        #expect(funding.fraction == nil)
        #expect(funding.showsProgress == false)
    }

    @Test("A progress bar appears once a jar reports a sum")
    func progressAppearsWithAJar() {
        let funding = CampaignPosterFunding(
            campaign: campaign(target: 20_000, collected: 5_000)
        )

        #expect(funding.showsProgress)
    }

    @Test("A finished poster drops the progress bar for its own final word")
    func finishedPosterHidesProgress() {
        let funding = CampaignPosterFunding(
            campaign: campaign(target: 20_000, collected: 20_000)
        )

        #expect(funding.isFinished)
        #expect(funding.fraction == 1)
        #expect(funding.showsProgress == false)
    }

    @Test("An empty funding state shows nothing at all")
    func noneShowsNothing() {
        #expect(CampaignPosterFunding.none.goal == nil)
        #expect(CampaignPosterFunding.none.collected == nil)
        #expect(CampaignPosterFunding.none.isFinished == false)
        #expect(CampaignPosterFunding.none.showsProgress == false)
    }

    // MARK: - Thumbnail cache

    @Test("A thumbnail cached before the jar moved is not reused after it")
    func thumbnailKeyTracksTheCollectedSum() throws {
        let template = try #require(Template.list.first)

        func key(collected: Double?) -> CampaignPosterThumbnailKey {
            CampaignPosterThumbnailRequest(
                campaign: campaign(collected: collected),
                template: template,
                composition: .poster,
                assets: .empty,
                pointSize: CGSize(width: 120, height: 120),
                displayScale: 2,
                colorScheme: .light,
                locale: Locale(identifier: "uk_UA")
            ).key
        }

        #expect(key(collected: 5_000) != key(collected: 9_000))
        #expect(key(collected: nil) != key(collected: 5_000))
    }

    @Test("Finishing a collection invalidates its cached thumbnail")
    func thumbnailKeyTracksTheFinishedFlag() throws {
        let template = try #require(Template.list.first)

        func key(closed: Bool) -> CampaignPosterThumbnailRefreshKey {
            CampaignPosterThumbnailRequest(
                campaign: campaign(collected: 5_000, closedByAuthor: closed),
                template: template,
                composition: .poster,
                assets: .empty,
                pointSize: CGSize(width: 120, height: 120),
                displayScale: 2,
                colorScheme: .light,
                locale: Locale(identifier: "uk_UA")
            ).refreshKey
        }

        #expect(key(closed: false) != key(closed: true))
    }
}

@Suite("Template catalogue")
struct TemplateCatalogueTests {
    @Test("The retired teal/purple template can no longer be chosen")
    func theRetiredTemplateIsGone() {
        #expect(Template.list[id: "b_tealPurpleRadial_roundedTrailing"] == nil)
    }

    @Test("Retiring one template left the rest of the catalogue alone")
    func theRestOfTheCatalogueSurvived() {
        #expect(Template.list.count == 29)
        // Series A's counterpart was not part of the request.
        #expect(Template.list[id: "a_tealPurpleRadial_roundedTrailing"] != nil)
    }

    @Test("A campaign saved on the retired template still renders")
    func aCampaignOnTheRetiredTemplateStillRenders() throws {
        // The entry left the catalogue, but its view did not: decoding a
        // campaign that points at it must still produce a drawable template.
        let retired = Template(
            name: "6",
            series: .b,
            gradient: .tealPurpleRadial,
            imagePlacement: .roundedTrailing
        )

        let decoded = try JSONDecoder().decode(
            Template.self,
            from: JSONEncoder().encode(retired)
        )

        #expect(decoded == retired)
        #expect(decoded.id == "b_tealPurpleRadial_roundedTrailing")
    }
}
