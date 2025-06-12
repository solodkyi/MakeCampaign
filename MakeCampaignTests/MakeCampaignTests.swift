//
//  MakeCampaignTests.swift
//  MakeCampaignTests
//
//  Created by Andrii Solodkyi on 5/1/25.
//

import XCTest
import ComposableArchitecture
@testable import MakeCampaign

@MainActor
final class MakeCampaignTests: XCTestCase {
    
    func test_campaignsList_initialState() async {
        let store = TestStore(
            initialState:
                AppFeature.State(campaignsList: .init())
        ) {
            AppFeature()
        } withDependencies: {
            $0.continuousClock = ImmediateClock()
        }
        
        store.exhaustivity = .off(showSkippedAssertions: false)
        
        store.assert {
            XCTAssertEqual($0.path.count, 0)
            XCTAssertEqual($0.campaignsList.campaigns.count, 0)
        }
    }
    
    func test_campaignsList_matches_saved_campaigns_count() async {
        @Shared(.campaigns) var campaigns = Campaign.mocks
        
        let store = TestStore(
            initialState:
                AppFeature.State(campaignsList: .init())
        ) {
            AppFeature()
        } withDependencies: {
            $0.continuousClock = ImmediateClock()
        }
        
        store.exhaustivity = .off(showSkippedAssertions: false)
        
        store.assert {
            XCTAssertEqual($0.path.count, 0)
            XCTAssertEqual($0.campaignsList.campaigns.count, campaigns.count)
        }
    }
    
    func test_campaignsList_requestsJarDetailsAndCalculatesProgress() async {
        @Shared(.campaigns) var campaigns = [Campaign(id: .init(0), target: 1_000_000, jar: .init(link: URL(string: "https://some.jar")!))]
        let store = TestStore(
            initialState:
                AppFeature.State(campaignsList: .init())
        ) {
            AppFeature()
        } withDependencies: {
            $0.continuousClock = ImmediateClock()
            $0.jarApiClient = .mock
        }
        
        store.exhaustivity = .off(showSkippedAssertions: false)
        await store.send(.campaignsList(.onViewInitialLoad))
        await store.skipReceivedActions()

        store.assert {
            XCTAssertNotNil($0.campaignsList.campaigns.first?.progress)
        }
    }
        
    func test_campaignDetails_presented_byTap() async {
        let campaign = Campaign.mock1
        @Shared(.campaigns) var campaigns = [campaign]
        
        let store = TestStore(
              initialState:
                AppFeature.State(campaignsList: .init())
            ) {
              AppFeature()
            } withDependencies: {
              $0.continuousClock = ImmediateClock()
            }
        store.exhaustivity = .off(showSkippedAssertions: false)
        await store.send(.campaignsList(.campaignSelected(campaign.id)))
        await store.skipReceivedActions()
        
        store.assert {
            $0.path[id: 0, case: \.details]?.$campaign.withLock {
                $0 = campaign
            }
            XCTAssertEqual($0.path.count, 1)
        }
    }
    
    func test_campaignDetails_campaign_deleted() async {
        let campaign = Campaign.mock1
        @Shared(.campaigns) var campaigns = [campaign]
        let store = TestStore(
              initialState:
                AppFeature.State(campaignsList: .init())
            ) {
              AppFeature()
            } withDependencies: {
              $0.continuousClock = ImmediateClock()
            }
        
        store.exhaustivity = .off(showSkippedAssertions: false)
        await store.send(.campaignsList(.campaignSelected(campaign.id)))
        await store.send(.path(.element(id: 0, action: .details(.onCampaignDeleteButtonTapped(campaign.id)))))
        await store.send(.path(.element(id: 0, action: .details(.destination(.presented(.alert(.confirmDeleteCampaign)))))))
        await store.skipReceivedActions()
        store.assert {
            XCTAssertEqual($0.path.count, 0)
            XCTAssertEqual($0.campaignsList.campaigns.count, 0)
        }
    }
    
    func test_campaignDetails_editCampaign() async {
        let campaign = Campaign.mock1
        @Shared(.campaigns) var campaigns = [campaign]
        let store = TestStore(
              initialState:
                AppFeature.State(campaignsList: .init())
            ) {
              AppFeature()
            } withDependencies: {
              $0.continuousClock = ImmediateClock()
            }
        store.exhaustivity = .off(showSkippedAssertions: false)
        await store.send(.campaignsList(.campaignSelected(campaign.id)))
        
        var updatedCampaign = campaign
        updatedCampaign.purpose = "updated campaign"
        updatedCampaign.target = 100_000
        
        await store.send(\.path[id: 0].details.binding.campaign, updatedCampaign)
        await store.send(\.path[id: 0].details.onSaveButtonTapped)
        await store.skipReceivedActions()

        store.assert {
            XCTAssertEqual($0.campaignsList.campaigns.first, updatedCampaign)
        }
    }
    
    // MARK: - Campaign Details Field Validation Tests
    
    func test_campaignDetails_nameField_validatesOnBindingChange() async throws {
        let campaign = Campaign(id: .init(0), purpose: "")
        @Shared(.campaigns) var campaigns = [campaign]
        guard let sharedCampaign = Shared($campaigns[id: campaign.id]) else {
            return XCTFail("Shared campaign is nil")
        }
        let store = TestStore(
            initialState: CampaignDetailsFeature.State(
                campaign: sharedCampaign
            )
        ) {
            CampaignDetailsFeature()
        } withDependencies: {
            $0.validationClient = .liveValue
        }
        store.exhaustivity = .off(showSkippedAssertions: false)
        
        await store.send(.onSaveButtonTapped)
        
        store.assert {
            XCTAssertFalse($0.validationErrors.name.isEmpty)
            XCTAssertEqual($0.validationErrors.name.first, .empty)
        }
        
        let newState = store.state
        newState.$campaign.withLock {
            $0.purpose = "Valid Campaign Name"
        }
        await store.send(\.binding.campaign, newState.campaign) {
            $0.$campaign.withLock {
                $0.purpose = "Valid Campaign Name"
            }
        }
        
        await store.send(.validateForm)
        
        store.assert {
            XCTAssertTrue($0.validationErrors.name.isEmpty)
            XCTAssertFalse($0.validationErrors.hasErrors(for: .name))
        }
    }
    
    // MARK: - Target Field Validation Tests
    
    func test_campaignDetails_targetField_fixedAfterError_clearsValidationError() async throws {
        let campaign = Campaign(id: .init(0), purpose: "Valid Name")
        @Shared(.campaigns) var campaigns = [campaign]
        guard let sharedCampaign = Shared($campaigns[id: campaign.id]) else {
            return XCTFail("Shared campaign is nil")
        }
        let store = TestStore(
            initialState: CampaignDetailsFeature.State(
                campaign: sharedCampaign
            )
        ) {
            CampaignDetailsFeature()
        } withDependencies: {
            $0.validationClient = .liveValue
        }
        store.exhaustivity = .off(showSkippedAssertions: false)
        
        var invalidCampaign = store.state.campaign
        invalidCampaign.formattedTarget = "invalid-amount"
        
        await store.send(\.binding.campaign, invalidCampaign) {
            $0.$campaign.withLock {
                $0.formattedTarget = "invalid-amount"
            }
        }
        
        await store.send(.onSaveButtonTapped)
        
        store.assert {
            XCTAssertFalse($0.validationErrors.target.isEmpty)
            XCTAssertTrue($0.validationErrors.hasErrors(for: .target))
            XCTAssertEqual($0.validationErrors.target.first, .invalidFormat)
            XCTAssertNil($0.focus)
        }
        
        var validCampaign = store.state.campaign
        validCampaign.formattedTarget = "1000"
        
        await store.send(\.binding.campaign, validCampaign) {
            $0.$campaign.withLock {
                $0.formattedTarget = "1000"
            }
        }
        
        await store.send(.validateForm)
        
        store.assert {
            XCTAssertTrue($0.validationErrors.target.isEmpty)
            XCTAssertFalse($0.validationErrors.hasErrors(for: .target))
        }
    }
    
    func test_campaignDetails_linkField_isNot_mandatory() async throws {
        let campaign = Campaign(id: .init(0),
                                purpose: "Valid Name")
        @Shared(.campaigns) var campaigns = [campaign]
        guard let sharedCampaign = Shared($campaigns[id: campaign.id]) else {
            return XCTFail("Shared campaign is nil")
        }
            let store = TestStore(
                initialState: CampaignDetailsFeature.State(
                    campaign: sharedCampaign,
                    isEditing: true
                )
            ) {
                CampaignDetailsFeature()
            } withDependencies: {
                $0.validationClient = .liveValue
            }
            store.exhaustivity = .off(showSkippedAssertions: false)
        
            await store.send(.onSaveButtonTapped)
            
            store.assert {
                XCTAssertTrue($0.validationErrors.link.isEmpty)
                XCTAssertFalse($0.validationErrors.hasErrors(for: .link))
            }
        }
    
    func test_campaignDetails_linkField_fixedAfterError_clearsValidationError() async throws {
            let campaign = Campaign(id: .init(0), purpose: "Valid Name")
            var invalidCampaign = campaign
            invalidCampaign.jarURLString = "invalid-url"
        
            @Shared(.campaigns) var campaigns = [invalidCampaign]
            guard let sharedCampaign = Shared($campaigns[id: campaign.id]) else {
                return XCTFail("Shared campaign is nil")
            }
            let store = TestStore(
                initialState: CampaignDetailsFeature.State(
                    campaign: sharedCampaign,
                    isEditing: true
                )
            ) {
                CampaignDetailsFeature()
            } withDependencies: {
                $0.validationClient = .liveValue
            }
            store.exhaustivity = .off(showSkippedAssertions: false)
            
            await store.send(.onSaveButtonTapped)
            
            store.assert {
                XCTAssertFalse($0.validationErrors.link.isEmpty)
                XCTAssertTrue($0.validationErrors.hasErrors(for: .link))
                XCTAssertNil($0.focus)
            }
            
            var fixedCampaign = store.state.campaign
            fixedCampaign.jarURLString = "https://example.com/validjar"
            
            await store.send(\.binding.campaign, fixedCampaign)
            await store.send(.validateForm)
            
            store.assert {
                XCTAssertTrue($0.validationErrors.link.isEmpty)
                XCTAssertFalse($0.validationErrors.hasErrors(for: .link))
            }
        }
    
    // MARK: - Image Field Validation Tests
    
    func test_campaignDetails_imageField_fixedAfterError_clearsValidationError() async throws {
        let campaign = Campaign(id: .init(0), image: nil, purpose: "Valid Name")
        @Shared(.campaigns) var campaigns = [campaign]
        
        guard let sharedCampaign = Shared($campaigns[id: campaign.id]) else {
            return XCTFail("Shared campaign is nil")
        }
        
        let store = TestStore(
            initialState: CampaignDetailsFeature.State(
                campaign: sharedCampaign
            )
        ) {
            CampaignDetailsFeature()
        } withDependencies: {
            $0.validationClient = .liveValue
        }
        store.exhaustivity = .off(showSkippedAssertions: false)
        
        await store.send(.onSaveButtonTapped)
        
        store.assert {
            XCTAssertFalse($0.validationErrors.image.isEmpty)
            XCTAssertTrue($0.validationErrors.hasErrors(for: .image))
            XCTAssertEqual($0.validationErrors.image.first, .missingImage)
            XCTAssertNil($0.focus)
        }
        
        let mockImageData = Data(repeating: 0, count: 100)
        var updatedCampaign = store.state.campaign
        updatedCampaign.image = .init(raw: mockImageData)
        
        await store.send(\.binding.campaign, updatedCampaign) {
            $0.$campaign.withLock {
                $0.image = .init(raw: mockImageData)
            }
        }
        
        await store.send(.validateForm)
        
        store.assert {
            XCTAssertTrue($0.validationErrors.image.isEmpty)
            XCTAssertFalse($0.validationErrors.hasErrors(for: .image))
        }
    }
    
    func test_campaignDetails_templateField_missingTemplate_showsValidationError_andResetsWhenTemplateApplied() async throws {
        let campaign = Campaign(id: .init(0), image: Campaign.Image(raw: Data()), purpose: "Valid Name")
        @Shared(.campaigns) var campaigns = [campaign]
        guard let sharedCampaign = Shared($campaigns[id: campaign.id]) else {
            return XCTFail("Shared campaign is nil")
        }
        let store = TestStore(
            initialState: CampaignDetailsFeature.State(
                campaign: sharedCampaign
            )
        ) {
            CampaignDetailsFeature()
        } withDependencies: {
            $0.validationClient = .liveValue
        }
        store.exhaustivity = .off(showSkippedAssertions: false)
        
        await store.send(.onSaveButtonTapped)
        
        store.assert {
            XCTAssertFalse($0.validationErrors.template.isEmpty)
            XCTAssertTrue($0.validationErrors.hasErrors(for: .template))
        }
        
        await store.send(.onTemplateButtonTapped)
        
        await store.send(\.destination.presented.templateSelection, .templateSelected(.init(name: "1", gradient: .linearPurple, imagePlacement: .topCenter)))
        await store.send(\.destination.presented.templateSelection, .doneButtonTapped)

        await store.skipReceivedActions()

        store.assert {
            XCTAssertTrue($0.validationErrors.isEmpty)
            XCTAssertFalse($0.validationErrors.hasErrors(for: .template))
        }
    }
    
    func test_campaignDetails_imagePreview_presentedOrHiddenByImageTap() async throws{
        let campaign = Campaign(id: .init(0), image: Campaign.Image(raw: Data()))
        @Shared(.campaigns) var campaigns = [campaign]
        guard let sharedCampaign = Shared($campaigns[id: campaign.id]) else {
            return XCTFail("Shared campaign is nil")
        }
        
        let store = TestStore(
            initialState: CampaignDetailsFeature.State(
                campaign: sharedCampaign
            )
        ) {
            CampaignDetailsFeature()
        }
        
        store.exhaustivity = .off(showSkippedAssertions: false)
        
        await store.send(.onImageTapped)
        
        store.assert {
            XCTAssertTrue($0.isPresentingImageOverlay)
        }
        
        await store.send(.onImageTapped)
        
        store.assert {
            XCTAssertFalse($0.isPresentingImageOverlay)
        }
    }

    func test_campaignTemplate_presentedByTap() async throws {
        let campaign = Campaign(id: .init(0), image: Campaign.Image(raw: Data()), purpose: "Valid Name")
        @Shared(.campaigns) var campaigns = [campaign]
        guard let sharedCampaign = Shared($campaigns[id: campaign.id]) else {
            return XCTFail("Shared campaign is nil")
        }
        let store = TestStore(
            initialState: CampaignDetailsFeature.State(
                campaign: sharedCampaign
            )
        ) {
            CampaignDetailsFeature()
        }
        
        store.exhaustivity = .off(showSkippedAssertions: false)
        
        await store.send(.onTemplateButtonTapped)
        
        store.assert {
            XCTAssertEqual($0.destination, .templateSelection(.init(campaign: sharedCampaign)))
        }
    }
    
    func test_campaignTemplate_hasNoSelectionAtStart() async throws {
        let campaign = Campaign(id: .init(0), image: Campaign.Image(raw: Data()), purpose: "Valid Name")
        @Shared(.campaigns) var campaigns = [campaign]
        guard let sharedCampaign = Shared($campaigns[id: campaign.id]) else {
            return XCTFail("Shared campaign is nil")
        }
        let store = TestStore(
            initialState: TemplateSelectionFeature.State(campaign: sharedCampaign)
        ) {
            TemplateSelectionFeature()
        }
        
        store.exhaustivity = .off(showSkippedAssertions: false)
        
        store.assert {
            XCTAssertNil($0.selectedTemplateID)
        }
    }
    
    func test_campaignTemplate_hasSelectionForCampaignWithTemplate() async throws {
        let campaignWithTemplate = Campaign(id: .init(0), image: Campaign.Image(raw: Data()), template: Template(name: "1", gradient: .linearPurple, imagePlacement: .topCenter), purpose: "Valid Name")
        @Shared(.campaigns) var campaigns = [campaignWithTemplate]
        guard let sharedCampaign = Shared($campaigns[id: campaignWithTemplate.id]) else {
            return XCTFail("Shared campaign is nil")
        }
        let store = TestStore(
            initialState: TemplateSelectionFeature.State(campaign: sharedCampaign)
        ) {
            TemplateSelectionFeature()
        }
        
        store.exhaustivity = .off(showSkippedAssertions: false)
        
        store.assert {
            XCTAssertNotNil($0.selectedTemplateID)
        }
    }
    
    func test_campaignTemplate_updatesCampaignTemplateOnSelectionAndConfirmation() async throws {
        let campaign = Campaign(id: .init(0), image: Campaign.Image(raw: Data()), purpose: "Valid Name")
        @Shared(.campaigns) var campaigns = [campaign]
        guard let sharedCampaign = Shared($campaigns[id: campaign.id]) else {
            return XCTFail("Shared campaign is nil")
        }
        let store = TestStore(initialState: CampaignDetailsFeature.State(campaign: sharedCampaign, destination: .templateSelection(.init(campaign: sharedCampaign)))) {
            CampaignDetailsFeature()
        }
        
        store.exhaustivity = .off(showSkippedAssertions: false)
        
        let template = Template(name: "1", gradient: .linearPurple, imagePlacement: .topCenter)
        
        await store.send(\.destination.presented.templateSelection, .templateSelected(template))
        await store.send(\.destination.presented.templateSelection, .doneButtonTapped)
        await store.skipReceivedActions()
        
        store.assert {
            XCTAssertEqual($0.campaign.template?.id, template.id)
        }
    }
    
    func test_campaignDetails_onCampaignSave_rendersImageAndSavesItToPhotoLibrary() async throws {
        let campaign = Campaign.mock1
        var isPhotoSavedInLibrary = false
        var isCampaignImageRendered = false
        
        @Shared(.campaigns) var campaigns = [campaign]
        guard let sharedCampaign = Shared($campaigns[id: campaign.id]) else {
            return XCTFail("Shared campaign is nil")
        }
        
        let store = TestStore(initialState: CampaignDetailsFeature.State(campaign: sharedCampaign)) {
            CampaignDetailsFeature()
        } withDependencies: {
            $0.photoLibrarySaver = .init(saveImage: { _ in
                isPhotoSavedInLibrary = true
            }, requestPermission: {
                .authorized
            })
            
            $0.campaignRenderer = .init(render: { _ in
                isCampaignImageRendered = true
                return UIImage()
            })
        }
            
        store.exhaustivity = .off(showSkippedAssertions: false)
        await store.send(.onSaveButtonTapped)
        await store.skipReceivedActions()
        
        store.assert { _ in
            XCTAssertTrue(isCampaignImageRendered)
            XCTAssertTrue(isPhotoSavedInLibrary)
        }
    }
    
    func test_campaignDetails_onCampaignSaveWithPhotoLibraryAccessDenied_presentsAlert() async {
        let campaign = Campaign.mock1
        var isSettingsOpened = false
        
        let store = TestStore(initialState: CampaignDetailsFeature.State(campaign: Shared(value: campaign))) {
            CampaignDetailsFeature()
        } withDependencies: {
            $0.photoLibrarySaver = .init(saveImage: { _ in
            
            }, requestPermission: {
                .denied
            })
            $0.openSettings = {
                isSettingsOpened = true
            }
        }
            
        store.exhaustivity = .off(showSkippedAssertions: false)
        
        await store.send(.onSaveButtonTapped)
        await store.skipReceivedActions()
        
        store.assert {
            XCTAssertTrue($0.destination?.isAlert ?? false)
            XCTAssertFalse(isSettingsOpened)
        }
        
        await store.send(\.destination.presented, .alert(.openAppSettings))
        
        store.assert { _ in
            XCTAssertTrue(isSettingsOpened)
        }
    }
}

extension CampaignDetailsFeature.Destination.State {
    var isAlert: Bool {
        guard case .alert = self else { return false }
        return true
    }
}
