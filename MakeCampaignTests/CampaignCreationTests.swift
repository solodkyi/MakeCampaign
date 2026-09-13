import CustomDump
import ComposableArchitecture
import CoreImage
import Foundation
import SwiftUI
import Testing
import UIKit

@testable import MakeCampaign

@Suite("Campaign creation model")
struct CampaignCreationModelTests {
    @Test("Editor tabs follow the creation workflow order")
    func editorTabOrder() {
        let expected: [CampaignCreationFeature.State.Tab] = [
            .template,
            .photo,
            .data,
            .qr,
        ]

        expectNoDifference(
            CampaignCreationFeature.State.Tab.allCases,
            expected
        )
    }

    @Test("Editor opens on the template tab")
    func editorDefaultTab() {
        let state = CampaignCreationFeature.State(
            campaign: Campaign(id: UUID(0), status: .draft),
            isNew: true
        )

        expectNoDifference(state.selectedTab, .template)
    }

    @Test("Editor tabs name the poster field they edit")
    func tabCopy() {
        expectNoDifference(
            CampaignCreationFeature.State.Tab.qr.title,
            "Ціль"
        )
        expectNoDifference(
            CampaignCreationFeature.State.Tab.data.title,
            "Призначення"
        )
    }

    @Test("Opening the editor disables a previously enabled QR code")
    func editorDisablesQRCode() {
        let state = CampaignCreationFeature.State(
            campaign: Campaign(
                id: UUID(0),
                status: .draft,
                showsQRCode: true
            ),
            isNew: false
        )

        #expect(state.campaign.showsQRCode == false)
        #expect(state.initialCampaign.showsQRCode == false)
    }

    @Test("Poster purpose uses meaningful copy when the campaign is blank")
    func posterPurposeCopy() {
        var campaign = Campaign(id: UUID(0), status: .draft)

        expectNoDifference(campaign.posterPurpose, "Назва збору")

        campaign.purpose = "Збір на дрони"
        expectNoDifference(campaign.posterPurpose, "Збір на дрони")
    }

    @Test("Legacy campaigns decode with creation-safe defaults")
    func legacyCampaignDefaults() throws {
        let json = Data(
            #"{"id":"00000000-0000-0000-0000-000000000001","purpose":"Аптечки","createdAt":0,"updatedAt":0}"#.utf8
        )

        let campaign = try JSONDecoder().decode(Campaign.self, from: json)

        expectNoDifference(campaign.status, .active)
        expectNoDifference(campaign.posterFormat, .square)
        expectNoDifference(campaign.shareCaption, "")
        #expect(campaign.showsQRCode == false)
    }

    @Test("Poster formats map to exact export dimensions")
    func posterFormatDimensions() {
        expectNoDifference(Campaign.PosterFormat.square.pixelSize, CGSize(width: 1_080, height: 1_080))
        expectNoDifference(Campaign.PosterFormat.portrait.pixelSize, CGSize(width: 1_080, height: 1_350))
        expectNoDifference(Campaign.PosterFormat.story.pixelSize, CGSize(width: 1_080, height: 1_920))
    }

    @Test("Target input groups digits while preserving editable decimal text")
    func targetInputFormatting() {
        let cases = [
            (input: "", expected: ""),
            (input: "20000", expected: "20,000"),
            (input: "20,000", expected: "20,000"),
            (input: "20000.", expected: "20,000."),
            (input: "20000.5", expected: "20,000.5"),
            (input: "20000,", expected: "20,000,"),
            (input: "20,000,", expected: "20,000,"),
            (input: "20,000,5", expected: "20,000.5"),
            (input: "invalid", expected: "invalid"),
        ]

        for testCase in cases {
            expectNoDifference(
                CampaignTargetInputFormatter.format(testCase.input),
                testCase.expected
            )
        }
    }

    @Test("Legacy images default to fill content mode")
    func legacyImageDefaults() throws {
        let json = Data(#"{"raw":null,"offset":[0,0],"scale":1,"referenceSize":[300,300]}"#.utf8)
        let image = try JSONDecoder().decode(Campaign.Image.self, from: json)
        expectNoDifference(image.contentMode, .fill)
    }

    @Test("Creation fields survive persistence")
    func creationFieldsRoundTrip() throws {
        let campaign = Campaign(
            id: UUID(0),
            status: .draft,
            posterFormat: .story,
            showsQRCode: true,
            shareCaption: "Підтримайте збір"
        )
        let decoded = try JSONDecoder().decode(Campaign.self, from: JSONEncoder().encode(campaign))
        expectNoDifference(decoded, campaign)
    }

    @Test("QR generation rejects empty input and renders a valid link")
    func qrGeneration() {
        #expect(QRCodeGenerator.image(for: "") == nil)
        let code = QRCodeGenerator.image(for: "https://send.monobank.ua/jar/example")
        #expect(code?.cgImage != nil)
    }

    @Test("Poster preview fits every export format inside the design stage")
    func posterPreviewFitsDesignStage() {
        let available = CGSize(width: 350, height: 350)

        expectNoDifference(
            CampaignPosterLayout.previewSize(for: .square, in: available),
            CGSize(width: 350, height: 350)
        )
        expectNoDifference(
            CampaignPosterLayout.previewSize(for: .portrait, in: available),
            CGSize(width: 280, height: 350)
        )
        expectNoDifference(
            CampaignPosterLayout.previewSize(for: .story, in: available),
            CGSize(width: 196.875, height: 350)
        )
    }

    @Test("Editor layout never emits invalid frame dimensions")
    func editorLayoutClampsTransientGeometry() {
        let collapsed = CampaignEditorLayout.metrics(
            availableHeight: 0,
            isTextEditing: false
        )
        let collapsedEditing = CampaignEditorLayout.metrics(
            availableHeight: 0,
            isTextEditing: true
        )

        expectNoDifference(collapsed.trayHeight, 0)
        expectNoDifference(collapsed.posterStageHeight, 0)
        expectNoDifference(collapsedEditing.trayHeight, 0)
        expectNoDifference(collapsedEditing.posterStageHeight, 0)
    }

    @Test("Editor layout preserves its intended dimensions when space is available")
    func editorLayoutPreservesNormalGeometry() {
        let regular = CampaignEditorLayout.metrics(
            availableHeight: 852,
            isTextEditing: false
        )
        let editing = CampaignEditorLayout.metrics(
            availableHeight: 852,
            isTextEditing: true
        )

        expectNoDifference(regular.trayHeight, 364)
        expectNoDifference(regular.posterStageHeight, 488)
        expectNoDifference(editing.trayHeight, 364)
        expectNoDifference(editing.posterStageHeight, 232)
    }

    @Test("QR overlay scales with both preview and exported poster")
    func qrOverlayScalesWithPoster() {
        expectNoDifference(CampaignPosterLayout.qrSideLength(for: 350), 42)
        expectNoDifference(CampaignPosterLayout.qrSideLength(for: 1_080), 129.6)
    }

    @Test("Poster hit testing prioritizes QR and text over an overlapping photo")
    func posterElementHitTesting() {
        let overlappingRegions: [CampaignPosterElement: CGRect] = [
            .photo: CGRect(x: 0, y: 0, width: 300, height: 300),
            .campaignTitle: CGRect(x: 40, y: 40, width: 180, height: 80),
            .target: CGRect(x: 80, y: 180, width: 140, height: 60),
            .qr: CGRect(x: 200, y: 200, width: 80, height: 80),
        ]

        expectNoDifference(
            CampaignPosterHitTesting.element(
                at: CGPoint(x: 210, y: 210),
                in: overlappingRegions
            ),
            .qr
        )
        expectNoDifference(
            CampaignPosterHitTesting.element(
                at: CGPoint(x: 100, y: 60),
                in: overlappingRegions
            ),
            .campaignTitle
        )
        expectNoDifference(
            CampaignPosterHitTesting.element(
                at: CGPoint(x: 120, y: 200),
                in: overlappingRegions
            ),
            .target
        )
        expectNoDifference(
            CampaignPosterHitTesting.element(
                at: CGPoint(x: 20, y: 250),
                in: overlappingRegions
            ),
            .photo
        )
        #expect(
            CampaignPosterHitTesting.element(
                at: CGPoint(x: 340, y: 340),
                in: overlappingRegions
            ) == nil
        )
    }

    @Test("Manual photo fitting suspends poster gesture and region work")
    func manualPhotoFittingSuspendsExpensiveInteractions() {
        #expect(
            CampaignPosterInteractionPolicy.isEnabled(
                isTransformingImage: false,
                hasCallbacks: true
            )
        )
        #expect(
            !CampaignPosterInteractionPolicy.isEnabled(
                isTransformingImage: true,
                hasCallbacks: true
            )
        )
        #expect(
            !CampaignPosterInteractionPolicy.isEnabled(
                isTransformingImage: false,
                hasCallbacks: false
            )
        )
    }

    @Test("Keyboard hides the poster selection highlight")
    func selectionHighlightYieldsToTheKeyboard() {
        #expect(
            CampaignPosterSelectionHighlightPolicy.isVisible(
                selection: .campaignTitle,
                isTextEditing: false
            )
        )
        #expect(
            !CampaignPosterSelectionHighlightPolicy.isVisible(
                selection: .campaignTitle,
                isTextEditing: true
            )
        )
        #expect(
            !CampaignPosterSelectionHighlightPolicy.isVisible(
                selection: .target,
                isTextEditing: true
            )
        )
        #expect(
            !CampaignPosterSelectionHighlightPolicy.isVisible(
                selection: nil,
                isTextEditing: false
            )
        )
    }

    @Test("Poster elements expose named editing actions where double tap adds behavior")
    func posterAccessibilityActions() {
        expectNoDifference(
            CampaignPosterElement.photo.accessibilityEditActionName,
            "Замінити фото"
        )
        expectNoDifference(
            CampaignPosterElement.campaignTitle.accessibilityEditActionName,
            "Редагувати назву"
        )
        expectNoDifference(
            CampaignPosterElement.target.accessibilityEditActionName,
            "Редагувати ціль"
        )
        #expect(CampaignPosterElement.qr.accessibilityEditActionName == nil)
    }

    @MainActor
    @Test("Selected photo is visible before a template is selected")
    func photoOnlyPosterDisplaysSelectedPhoto() throws {
        let photo = UIGraphicsImageRenderer(size: CGSize(width: 20, height: 20)).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 20, height: 20))
        }
        let campaign = Campaign(
            id: UUID(0),
            image: .init(raw: try #require(photo.pngData())),
            template: nil,
            status: .draft
        )
        let renderer = ImageRenderer(
            content: CampaignPosterView(
                campaign: campaign,
                assets: CampaignPosterPreviewAssets(
                    photo: photo,
                    qrCode: nil,
                    signature: "photo"
                )
            )
                .frame(width: 100, height: 100)
        )
        renderer.scale = 1
        let rendered = try #require(renderer.uiImage)

        expectNoDifference(try centerRGBA(of: rendered), [255, 0, 0, 255])
    }

    @MainActor
    @Test("Renderer honors every selected poster format")
    func rendererFormats() async throws {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8)).image { context in
            UIColor.orange.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        }
        let data = try #require(image.pngData())

        for format in Campaign.PosterFormat.allCases {
            let campaign = Campaign(
                id: UUID(0),
                image: .init(raw: data),
                template: try #require(Template.list.first),
                purpose: "Аптечки",
                posterFormat: format
            )
            let rendered = try await CampaignRenderer.liveValue.render(campaign)
            expectNoDifference(rendered.size, format.pixelSize)
        }
    }

    @Test("A supporting jar needs both targets")
    func supportingJarNeedsBothTargets() {
        let campaign = Campaign.validDraft(isSupportingJar: true)

        let validation = CampaignCreationFeature().validation(for: campaign)

        #expect(validation.generalTarget == "Вкажіть загальну ціль збору.")
        #expect(validation.personalTarget == "Вкажіть свою ціль.")
        #expect(!validation.isValid)
    }

    @Test("My goal may not exceed the general one")
    func personalTargetMayNotExceedTheGeneralOne() {
        var campaign = Campaign.validDraft(isSupportingJar: true)
        campaign.target = 1_000_000
        campaign.personalTarget = 2_000_000

        let validation = CampaignCreationFeature().validation(for: campaign)

        #expect(validation.personalTarget == "Моя ціль не може бути більшою за загальну ціль.")
        #expect(!validation.isValid)
    }

    @Test("Equal targets are allowed")
    func equalTargetsAreAllowed() {
        var campaign = Campaign.validDraft(isSupportingJar: true)
        campaign.target = 1_000_000
        campaign.personalTarget = 1_000_000

        let validation = CampaignCreationFeature().validation(for: campaign)

        #expect(validation.personalTarget == nil)
        #expect(validation.generalTarget == nil)
    }

    @Test("An ordinary campaign ignores the personal target entirely")
    func ordinaryCampaignIgnoresThePersonalTarget() {
        var campaign = Campaign.validDraft(isSupportingJar: false)
        campaign.target = nil
        campaign.personalTarget = 2_000_000

        let validation = CampaignCreationFeature().validation(for: campaign)

        #expect(validation.generalTarget == nil)
        #expect(validation.personalTarget == nil)
    }

    @Test("An ordinary campaign ignores even an oversized leftover personal target")
    func ordinaryCampaignIgnoresAnOversizedLeftoverPersonalTarget() {
        // Це саме випадок «вимкнули перемикач, а особиста ціль лишилась»:
        // тут `target` заповнено, тож без охорони `isSupportingJar` спрацював
        // би саме розрахунок перевищення — перевіряємо, що цього не стається.
        var campaign = Campaign.validDraft(isSupportingJar: false)
        campaign.target = 1_000_000
        campaign.personalTarget = 2_000_000

        let validation = CampaignCreationFeature().validation(for: campaign)

        #expect(validation.generalTarget == nil)
        #expect(validation.personalTarget == nil)
    }
}

private func centerRGBA(of image: UIImage) throws -> [UInt8] {
    let ciImage = try #require(CIImage(image: image))
    let center = CGPoint(x: ciImage.extent.midX, y: ciImage.extent.midY)
    let sampleRect = CGRect(x: center.x, y: center.y, width: 1, height: 1)
    let average = try #require(
        CIFilter(
            name: "CIAreaAverage",
            parameters: [kCIInputImageKey: ciImage, kCIInputExtentKey: CIVector(cgRect: sampleRect)]
        )?.outputImage
    )
    var bytes = [UInt8](repeating: 0, count: 4)
    CIContext().render(
        average,
        toBitmap: &bytes,
        rowBytes: 4,
        bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
        format: .RGBA8,
        colorSpace: CGColorSpaceCreateDeviceRGB()
    )
    return bytes
}

@MainActor
@Suite("Campaign creation reducer", .serialized)
struct CampaignCreationReducerTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test("Untouched editor is not persisted; first edit creates one draft")
    func autosavesFirstMeaningfulEdit() async {
        @Shared(value: []) var campaigns: IdentifiedArrayOf<Campaign>
        let campaign = Campaign(id: UUID(0), status: .draft, createdAt: now, updatedAt: now)
        let store = TestStore(
            initialState: CampaignCreationFeature.State(
                campaign: campaign,
                campaigns: $campaigns,
                isNew: true
            )
        ) {
            CampaignCreationFeature()
        } withDependencies: {
            $0.date.now = now.addingTimeInterval(60)
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        #expect(campaigns.isEmpty)
        await store.send(.binding(.set(\.campaign.purpose, "Аптечки")))
        #expect(campaigns.count == 1)
        expectNoDifference(campaigns.first?.status, .draft)
        expectNoDifference(campaigns.first?.purpose, "Аптечки")
    }

    @Test("Invalid export explains missing poster inputs")
    func validatesBeforeExport() async {
        @Shared(value: []) var campaigns: IdentifiedArrayOf<Campaign>
        let store = TestStore(
            initialState: CampaignCreationFeature.State(
                campaign: Campaign(id: UUID(0), status: .draft),
                campaigns: $campaigns,
                isNew: true
            )
        ) {
            CampaignCreationFeature()
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.shareButtonTapped)
        #expect(store.state.validation.title != nil)
        #expect(store.state.validation.photo != nil)
        #expect(store.state.validation.template != nil)
        #expect(store.state.isRendering == false)
        #expect(store.state.exportNotice?.id == .validationFailed)
    }

    @Test("Photo processing failure keeps the previous campaign intact")
    func photoFailure() async {
        @Shared(value: []) var campaigns: IdentifiedArrayOf<Campaign>
        let campaign = Campaign(id: UUID(0), status: .draft)
        let store = TestStore(
            initialState: CampaignCreationFeature.State(
                campaign: campaign,
                campaigns: $campaigns,
                isNew: true
            )
        ) {
            CampaignCreationFeature()
        } withDependencies: {
            $0.campaignImageProcessor.process = { _ in
                throw CampaignImageProcessor.ProcessingError.invalidImage
            }
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.photoPicked(Data([0x00])))
        await store.skipReceivedActions()
        #expect(store.state.campaign == campaign)
        guard case .failed = store.state.photoPhase else {
            Issue.record("Expected a retryable photo failure")
            return
        }
    }

    @Test("Successful photo selection restores the poster editor")
    func successfulPhotoSelectionCollapsesExpandedPicker() async {
        @Shared(value: []) var campaigns: IdentifiedArrayOf<Campaign>
        let replacement = Data([0x02])
        var state = CampaignCreationFeature.State(
            campaign: Campaign(id: UUID(0), status: .draft),
            campaigns: $campaigns,
            isNew: true
        )
        state.isPhotoPickerExpanded = true
        let store = TestStore(initialState: state) {
            CampaignCreationFeature()
        } withDependencies: {
            $0.campaignImageProcessor.process = { _ in replacement }
            $0.date.now = now
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.photoPicked(replacement))
        await store.skipReceivedActions()

        #expect(store.state.photoPhase == .idle)
        #expect(store.state.isPhotoPickerExpanded == false)
    }

    @Test("Leaving the Photo tab restores the poster editor")
    func switchingTabsCollapsesExpandedPicker() async {
        @Shared(value: []) var campaigns: IdentifiedArrayOf<Campaign>
        var state = CampaignCreationFeature.State(
            campaign: Campaign(id: UUID(0), status: .draft),
            campaigns: $campaigns,
            isNew: true
        )
        state.isPhotoPickerExpanded = true
        let store = TestStore(initialState: state) {
            CampaignCreationFeature()
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.tabSelected(.template))

        #expect(store.state.selectedTab == .template)
        #expect(store.state.isPhotoPickerExpanded == false)
    }

    @Test("Replacing a photo resets its crop and preserves its content mode")
    func replacementResetsCrop() async {
        @Shared(value: []) var campaigns: IdentifiedArrayOf<Campaign>
        let replacement = Data([0x02])
        let updatedAt = now.addingTimeInterval(60)
        let campaign = Campaign(
            id: UUID(0),
            image: .init(
                raw: Data([0x01]),
                offset: CGSize(width: 40, height: -20),
                scale: 2.5,
                referenceSize: CGSize(width: 900, height: 600),
                contentMode: .fit
            ),
            status: .draft,
            createdAt: now,
            updatedAt: now
        )
        var state = CampaignCreationFeature.State(
            campaign: campaign,
            campaigns: $campaigns,
            isNew: true
        )
        state.validation.photo = "Оберіть фото для постера."
        let store = TestStore(initialState: state) {
            CampaignCreationFeature()
        } withDependencies: {
            $0.campaignImageProcessor.process = { _ in replacement }
            $0.date.now = updatedAt
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.photoPicked(replacement))
        await store.skipReceivedActions()

        expectNoDifference(
            store.state.campaign.image,
            Campaign.Image(raw: replacement, contentMode: .fit)
        )
        #expect(store.state.photoPhase == .idle)
        #expect(store.state.validation.photo == nil)
        expectNoDifference(campaigns.first?.image, store.state.campaign.image)
        expectNoDifference(campaigns.first?.updatedAt, updatedAt)
    }

    @Test("Only the latest photo selection updates the campaign")
    func latestPhotoSelectionWins() async {
        @Shared(value: []) var campaigns: IdentifiedArrayOf<Campaign>
        let first = Data([0x01])
        let second = Data([0x02])
        let firstStarted = AsyncStream<Void>.makeStream()
        let releaseFirst = AsyncStream<Void>.makeStream()
        let didCancelFirst = LockIsolated(false)
        var firstStartedIterator = firstStarted.stream.makeAsyncIterator()
        let store = TestStore(
            initialState: CampaignCreationFeature.State(
                campaign: Campaign(id: UUID(0), status: .draft),
                campaigns: $campaigns,
                isNew: true
            )
        ) {
            CampaignCreationFeature()
        } withDependencies: {
            $0.campaignImageProcessor.process = { data in
                if data == first {
                    firstStarted.continuation.yield()
                    return try await withTaskCancellationHandler {
                        for await _ in releaseFirst.stream {
                            break
                        }
                        try Task.checkCancellation()
                        return data
                    } onCancel: {
                        didCancelFirst.withValue { $0 = true }
                        releaseFirst.continuation.yield()
                    }
                }
                return data
            }
            $0.date.now = now
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.photoPicked(first))
        _ = await firstStartedIterator.next()
        await store.send(.photoPicked(second))
        await store.receive(.photoProcessed(second))
        #expect(didCancelFirst.value)

        releaseFirst.continuation.yield()
        releaseFirst.continuation.finish()
        await store.finish()

        expectNoDifference(store.state.campaign.image?.raw, second)
        #expect(store.state.photoPhase == .idle)
    }

    @Test("Saving renders the poster into the photo library without sharing")
    func saveRendersIntoPhotoLibrary() async throws {
        @Shared(value: []) var campaigns: IdentifiedArrayOf<Campaign>
        let image = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4)).image { context in
            UIColor.orange.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
        }
        let campaign = Campaign(
            id: UUID(0),
            image: .init(raw: try #require(image.pngData())),
            template: try #require(Template.list.first),
            purpose: "Аптечки",
            status: .draft
        )
        let savedImage = LockIsolated<UIImage?>(nil)
        let store = TestStore(
            initialState: CampaignCreationFeature.State(
                campaign: campaign,
                campaigns: $campaigns,
                isNew: true
            )
        ) {
            CampaignCreationFeature()
        } withDependencies: {
            $0.campaignRenderer = CampaignRenderer(render: { _ in image })
            $0.photoLibrarySaver = .init(
                saveImage: { image in
                    savedImage.withValue { $0 = image }
                },
                requestPermission: { .authorized }
            )
            $0.date.now = Date(timeIntervalSince1970: 1_800_000_000)
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.saveButtonTapped)
        await store.skipReceivedActions()

        #expect(savedImage.value != nil)
        expectNoDifference(store.state.campaign.status, .active)
        expectNoDifference(campaigns.first?.status, .active)
        #expect(store.state.exportNotice?.id == .saved)
        #expect(store.state.presentation == nil)
    }

    @Test("Sharing promotes the draft and presents the system share sheet")
    func successfulSharePromotesDraft() async throws {
        @Shared(value: []) var campaigns: IdentifiedArrayOf<Campaign>
        let image = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4)).image { context in
            UIColor.orange.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
        }
        let png = try #require(image.pngData())
        let campaign = Campaign(
            id: UUID(0),
            image: .init(raw: png),
            template: try #require(Template.list.first),
            purpose: "Аптечки",
            status: .draft
        )
        let store = TestStore(
            initialState: CampaignCreationFeature.State(
                campaign: campaign,
                campaigns: $campaigns,
                isNew: true
            )
        ) {
            CampaignCreationFeature()
        } withDependencies: {
            $0.campaignRenderer = CampaignRenderer(render: { _ in image })
            $0.date.now = Date(timeIntervalSince1970: 1_800_000_000)
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.shareButtonTapped)
        await store.skipReceivedActions()
        expectNoDifference(store.state.campaign.status, .active)
        expectNoDifference(campaigns.first?.status, .active)
        #expect(store.state.sharePayload?.pngData.isEmpty == false)
        guard case .share = store.state.presentation else {
            Issue.record("Expected system sharing after rendering")
            return
        }
    }

    @Test("Render failure keeps the campaign as a draft and supports retry")
    func failedRenderKeepsDraft() async throws {
        @Shared(value: []) var campaigns: IdentifiedArrayOf<Campaign>
        let image = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4)).image { _ in }
        let campaign = Campaign(
            id: UUID(0),
            image: .init(raw: try #require(image.pngData())),
            template: try #require(Template.list.first),
            purpose: "Аптечки",
            status: .draft
        )
        let store = TestStore(
            initialState: CampaignCreationFeature.State(
                campaign: campaign,
                campaigns: $campaigns,
                isNew: true
            )
        ) {
            CampaignCreationFeature()
        } withDependencies: {
            $0.campaignRenderer = CampaignRenderer(render: { _ in
                throw CampaignRenderer.Error.renderingFailed
            })
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.shareButtonTapped)
        await store.skipReceivedActions()
        expectNoDifference(store.state.campaign.status, .draft)
        #expect(store.state.exportNotice?.id == .renderFailed)
        #expect(store.state.sharePayload == nil)
    }
}

@MainActor
@Suite("Campaign creation routing")
struct CampaignCreationRoutingTests {
    @Test("Campaign list shows active campaigns and drafts together")
    func unifiedList() {
        @Shared(value: [
            Campaign(id: UUID(0), purpose: "Активний", status: .active),
            Campaign(id: UUID(1), purpose: "Чернетка", status: .draft),
        ]) var campaigns: IdentifiedArrayOf<Campaign>
        let state = CampaignsFeature.State(campaigns: $campaigns)

        expectNoDifference(state.visibleCampaigns.map(\.purpose), ["Активний", "Чернетка"])
    }

    @Test("Create intent opens a deterministic untouched editor")
    func createRoute() async {
        @Shared(value: []) var campaigns: IdentifiedArrayOf<Campaign>
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let id = UUID(42)
        let store = TestStore(
            initialState: AppFeature.State(
                campaignsList: CampaignsFeature.State(campaigns: $campaigns)
            )
        ) {
            AppFeature()
        } withDependencies: {
            $0.uuid = .constant(id)
            $0.date.now = now
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.campaignsList(.createCampaignTapped))
        #expect(store.state.path.count == 1)
        #expect(store.state.path[id: 0, case: \.editor]?.campaign.id == id)
        #expect(store.state.path[id: 0, case: \.editor]?.campaign.status == .draft)
        #expect(campaigns.isEmpty)
    }
}

extension Campaign {
    /// Збір, у якому все інше вже правильне: тести цілей мають падати саме
    /// на цілях, а не на відсутньому фото чи шаблоні.
    static func validDraft(isSupportingJar: Bool) -> Campaign {
        Campaign(
            id: UUID(uuidString: "00000000-0000-0000-0000-00000000C001")!,
            image: Campaign.Image(raw: onePixelPNG),
            template: Template.list[0],
            purpose: "Збір на пікап",
            target: nil,
            isSupportingJar: isSupportingJar
        )
    }

    private static let onePixelPNG: Data = {
        UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).pngData { context in
            UIColor.systemTeal.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
    }()
}
