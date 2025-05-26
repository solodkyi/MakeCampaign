//
//  MakeCampaignTests.swift
//  MakeCampaignTests
//
//  Created by Andrii Solodkyi on 5/1/25.
//

import XCTest
import ComposableArchitecture
@testable import MakeCampaign

final class MakeCampaignTests: XCTestCase {
    
    func test_campaignsList_initialState() async {
        let store = TestStore(
            initialState:
                AppFeature.State(campaignsList: .init())
        ) {
            AppFeature()
        } withDependencies: {
            $0.continuousClock = ImmediateClock()
            $0.dataManager = .mock(initialData: nil)
        }
        
        store.exhaustivity = .off(showSkippedAssertions: false)
        
        store.assert {
            XCTAssertEqual($0.path.count, 0)
            XCTAssertEqual($0.campaignsList.campaigns.count, 0)
        }
    }
    
    func test_campaignsList_matches_saved_campaigns_count() async {
        let campaigns: IdentifiedArrayOf<Campaign> = Campaign.mocks
        let store = TestStore(
            initialState:
                AppFeature.State(campaignsList: .init())
        ) {
            AppFeature()
        } withDependencies: {
            $0.continuousClock = ImmediateClock()
            $0.dataManager = .mock(initialData: try? JSONEncoder().encode(campaigns))
        }
        
        store.exhaustivity = .off(showSkippedAssertions: false)
        
        store.assert {
            XCTAssertEqual($0.path.count, 0)
            XCTAssertEqual($0.campaignsList.campaigns.count, campaigns.count)
        }
    }
    
    func test_campaignsList_requestsJarDetailsAndCalculatesProgress() async {
        let campaignWithJarLink = Campaign(id: .init(0), target: 1_000_000, jar: .init(link: URL(string: "https://some.jar")!))
        let store = await TestStore(
            initialState:
                AppFeature.State(campaignsList: .init())
        ) {
            AppFeature()
        } withDependencies: {
            $0.continuousClock = ImmediateClock()
            $0.dataManager = .mock(initialData: try? JSONEncoder().encode([campaignWithJarLink]))
            $0.jarApiClient = .mock
        }
        
        store.exhaustivity = .off(showSkippedAssertions: false)
        await store.send(.campaignsList(.onViewInitialLoad))
        await store.skipReceivedActions()

        await store.assert {
            XCTAssertNotNil($0.campaignsList.campaigns.first?.progress)
        }
    }
        
    func test_campaignDetails_presented_byTap() async {
        let campaign = Campaign.mock1
        let store = TestStore(
              initialState:
                AppFeature.State(campaignsList: .init())
            ) {
              AppFeature()
            } withDependencies: {
              $0.continuousClock = ImmediateClock()
              $0.dataManager = .mock(initialData: try? JSONEncoder().encode([campaign]))
            }
        store.exhaustivity = .off(showSkippedAssertions: false)
        await store.send(.campaignsList(.campaignSelected(campaign.id)))
        
        store.assert {
            $0.path[id: 0, case: /AppFeature.Path.State.details]?.campaign = campaign
            XCTAssertEqual($0.path.count, 1)
        }
    }
    
    func test_campaignDetails_campaign_deleted() async {
        let campaign = Campaign.mock1
        let store = TestStore(
              initialState:
                AppFeature.State(campaignsList: .init())
            ) {
              AppFeature()
            } withDependencies: {
              $0.continuousClock = ImmediateClock()
              $0.dataManager = .mock(initialData: try? JSONEncoder().encode([campaign]))
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
        let store = TestStore(
              initialState:
                AppFeature.State(campaignsList: .init())
            ) {
              AppFeature()
            } withDependencies: {
              $0.continuousClock = ImmediateClock()
              $0.dataManager = .mock(initialData: try? JSONEncoder().encode([campaign]))
            }
        store.exhaustivity = .off(showSkippedAssertions: false)
        await store.send(.campaignsList(.campaignSelected(campaign.id)))
        
        var updatedCampaign = campaign
        updatedCampaign.purpose = "updated campaign"
        updatedCampaign.target = 100_000
        
        await store.send(.path(.element(id: 0, action: .details(.binding(.set(\.$campaign, updatedCampaign))))))
        await store.send(.path(.element(id: 0, action: .details(.onSaveButtonTapped))))
        await store.skipReceivedActions()

        await store.assert {
            XCTAssertEqual($0.campaignsList.campaigns.first, updatedCampaign)
        }
    }
    
    // MARK: - Campaign Details Field Validation Tests
    
    func test_campaignDetails_nameField_emptyName_showsValidationError() async {
        let store = TestStore(
            initialState: CampaignDetailsFeature.State(
                campaign: Campaign(id: .init(0), purpose: "")
            )
        ) {
            CampaignDetailsFeature()
        } withDependencies: {
            $0.validationClient = .liveValue
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.onSaveButtonTapped)
        
        await store.assert {
            XCTAssertFalse($0.isFormValid)
            XCTAssertFalse($0.validationErrors.name.isEmpty)
            XCTAssertTrue($0.validationErrors.hasErrors(for: .name))
            XCTAssertEqual($0.validationErrors.name.first, .empty)
        }
    }
    
    func test_campaignDetails_nameField_validName_noValidationError() async {
        let store = TestStore(
            initialState: CampaignDetailsFeature.State(
                campaign: Campaign(id: .init(0), purpose: "Valid Campaign Name")
            )
        ) {
            CampaignDetailsFeature()
        } withDependencies: {
            $0.validationClient = .liveValue
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.onSaveButtonTapped)
        
        await store.assert {
            XCTAssertTrue($0.validationErrors.name.isEmpty)
            XCTAssertFalse($0.validationErrors.hasErrors(for: .name))
        }
    }
    
    func test_campaignDetails_nameField_validatesOnBindingChange() async {
        let store = TestStore(
            initialState: CampaignDetailsFeature.State(
                campaign: Campaign(id: .init(0), purpose: "")
            )
        ) {
            CampaignDetailsFeature()
        } withDependencies: {
            $0.validationClient = .liveValue
        }
        store.exhaustivity = .off(showSkippedAssertions: false)
        
        await store.send(.onSaveButtonTapped)
        
        await store.assert {
            XCTAssertFalse($0.validationErrors.name.isEmpty)
            XCTAssertEqual($0.validationErrors.name.first, .empty)
        }
        
        var newState = store.state
        newState.campaign.purpose = "Valid Campaign Name"
        await store.send(.binding(.set(\.$campaign, newState.campaign))) {
            $0.campaign.purpose = "Valid Campaign Name"
        }
        
        await store.send(.validateForm)
        
        await store.assert {
            XCTAssertTrue($0.validationErrors.name.isEmpty)
            XCTAssertFalse($0.validationErrors.hasErrors(for: .name))
        }
    }
    
    // MARK: - Target Field Validation Tests
    
    func test_campaignDetails_targetField_emptyTarget_noValidationError() async {
        let store = TestStore(
            initialState: CampaignDetailsFeature.State(
                campaign: Campaign(id: .init(0), purpose: "Valid Name", target: nil)
            )
        ) {
            CampaignDetailsFeature()
        } withDependencies: {
            $0.validationClient = .liveValue
        }
        store.exhaustivity = .off(showSkippedAssertions: false)
        
        await store.send(.onSaveButtonTapped)
        
        await store.assert {
            XCTAssertTrue($0.validationErrors.target.isEmpty)
            XCTAssertFalse($0.validationErrors.hasErrors(for: .target))
        }
    }
    
    func test_campaignDetails_targetField_validTargetFormat_noValidationError() async {
        let store = TestStore(
            initialState: CampaignDetailsFeature.State(
                campaign: Campaign(id: .init(0), purpose: "Valid Name", target: 1000.0)
            )
        ) {
            CampaignDetailsFeature()
        } withDependencies: {
            $0.validationClient = .liveValue
        }
        store.exhaustivity = .off(showSkippedAssertions: false)
        
        await store.send(.onSaveButtonTapped)
        
        await store.assert {
            XCTAssertTrue($0.validationErrors.target.isEmpty)
            XCTAssertFalse($0.validationErrors.hasErrors(for: .target))
        }
    }
    
    func test_campaignDetails_targetField_invalidFormat_showsValidationError() async {
        let campaign = Campaign(id: .init(0), purpose: "Valid Name")
        let store = TestStore(
            initialState: CampaignDetailsFeature.State(
                campaign: campaign
            )
        ) {
            CampaignDetailsFeature()
        } withDependencies: {
            $0.validationClient = .liveValue
        }
        store.exhaustivity = .off(showSkippedAssertions: false)
        
        var updatedCampaign = store.state.campaign
        updatedCampaign.formattedTarget = "invalid-amount"
        
        await store.send(.binding(.set(\.$campaign, updatedCampaign))) {
            $0.campaign.formattedTarget = "invalid-amount"
        }
        
        await store.send(.onSaveButtonTapped)
        
        await store.assert {
            XCTAssertFalse($0.validationErrors.target.isEmpty)
            XCTAssertTrue($0.validationErrors.hasErrors(for: .target))
            XCTAssertEqual($0.validationErrors.target.first, .invalidFormat)
        }
    }
    
    func test_campaignDetails_targetField_fixedAfterError_clearsValidationError() async {
        let campaign = Campaign(id: .init(0), purpose: "Valid Name")
        let store = TestStore(
            initialState: CampaignDetailsFeature.State(
                campaign: campaign
            )
        ) {
            CampaignDetailsFeature()
        } withDependencies: {
            $0.validationClient = .liveValue
        }
        store.exhaustivity = .off(showSkippedAssertions: false)
        
        var invalidCampaign = store.state.campaign
        invalidCampaign.formattedTarget = "invalid-amount"
        
        await store.send(.binding(.set(\.$campaign, invalidCampaign))) {
            $0.campaign.formattedTarget = "invalid-amount"
        }
        
        await store.send(.onSaveButtonTapped)
        
        await store.assert {
            XCTAssertFalse($0.validationErrors.target.isEmpty)
            XCTAssertEqual($0.validationErrors.target.first, .invalidFormat)
        }
        
        var validCampaign = store.state.campaign
        validCampaign.formattedTarget = "1000"
        
        await store.send(.binding(.set(\.$campaign, validCampaign))) {
            $0.campaign.formattedTarget = "1000"
        }
        
        await store.send(.validateForm)
        
        await store.assert {
            XCTAssertTrue($0.validationErrors.target.isEmpty)
            XCTAssertFalse($0.validationErrors.hasErrors(for: .target))
        }
    }
    
    func test_campaignDetails_linkField_isNot_mandatory() async {
            let store = TestStore(
                initialState: CampaignDetailsFeature.State(
                    campaign: Campaign(id: .init(0),
                                       purpose: "Valid Name"),
                    isEditing: true
                )
            ) {
                CampaignDetailsFeature()
            } withDependencies: {
                $0.validationClient = .liveValue
            }
            store.exhaustivity = .off(showSkippedAssertions: false)
        
            await store.send(.onSaveButtonTapped)
            
            await store.assert {
                XCTAssertTrue($0.validationErrors.link.isEmpty)
                XCTAssertFalse($0.validationErrors.hasErrors(for: .link))
            }
        }
    
    func test_campaignDetails_linkField_invalidURL_showsValidationError() async {
            let campaign = Campaign(id: .init(0), purpose: "Valid Name")
            var updatedCampaign = campaign
            updatedCampaign.jarURLString = "invalid-url"
            
            let store = TestStore(
                initialState: CampaignDetailsFeature.State(
                    campaign: updatedCampaign,
                    isEditing: true
                )
            ) {
                CampaignDetailsFeature()
            } withDependencies: {
                $0.validationClient = .liveValue
            }
            store.exhaustivity = .off(showSkippedAssertions: false)
            
            await store.send(.onSaveButtonTapped)
            
            await store.assert {
                XCTAssertFalse($0.validationErrors.link.isEmpty)
                XCTAssertTrue($0.validationErrors.hasErrors(for: .link))
            }
        }
    
    func test_campaignDetails_linkField_validURL_noValidationError() async {
            let campaign = Campaign(id: .init(0), purpose: "Valid Name")
            var updatedCampaign = campaign
            updatedCampaign.jarURLString = "https://example.com/validjar"
            
            let store = TestStore(
                initialState: CampaignDetailsFeature.State(
                    campaign: updatedCampaign,
                    isEditing: true
                )
            ) {
                CampaignDetailsFeature()
            } withDependencies: {
                $0.validationClient = .liveValue
            }
            store.exhaustivity = .off(showSkippedAssertions: false)
            
            await store.send(.onSaveButtonTapped)
            
            await store.assert {
                XCTAssertTrue($0.validationErrors.link.isEmpty)
                XCTAssertFalse($0.validationErrors.hasErrors(for: .link))
            }
        }
    
    func test_campaignDetails_linkField_fixedAfterError_clearsValidationError() async {
            let campaign = Campaign(id: .init(0), purpose: "Valid Name")
            var invalidCampaign = campaign
            invalidCampaign.jarURLString = "invalid-url"
            
            let store = TestStore(
                initialState: CampaignDetailsFeature.State(
                    campaign: invalidCampaign,
                    isEditing: true
                )
            ) {
                CampaignDetailsFeature()
            } withDependencies: {
                $0.validationClient = .liveValue
            }
            store.exhaustivity = .off(showSkippedAssertions: false)
            
            await store.send(.onSaveButtonTapped)
            
            await store.assert {
                XCTAssertFalse($0.validationErrors.link.isEmpty)
                XCTAssertTrue($0.validationErrors.hasErrors(for: .link))
            }
            
            var fixedCampaign = store.state.campaign
            fixedCampaign.jarURLString = "https://example.com/validjar"
            
            await store.send(.binding(.set(\.$campaign, fixedCampaign)))
            await store.send(.validateForm)
            
            await store.assert {
                XCTAssertTrue($0.validationErrors.link.isEmpty)
                XCTAssertFalse($0.validationErrors.hasErrors(for: .link))
            }
        }
    
    // MARK: - Image Field Validation Tests
    
    func test_campaignDetails_imageField_missingImage_showsValidationError() async {
        let store = TestStore(
            initialState: CampaignDetailsFeature.State(
                campaign: Campaign(id: .init(0), image: nil, purpose: "Valid Name")
            )
        ) {
            CampaignDetailsFeature()
        } withDependencies: {
            $0.validationClient = .liveValue
        }
        store.exhaustivity = .off(showSkippedAssertions: false)
        
        await store.send(.onSaveButtonTapped)
        
        await store.assert {
            XCTAssertFalse($0.validationErrors.image.isEmpty)
            XCTAssertTrue($0.validationErrors.hasErrors(for: .image))
            XCTAssertEqual($0.validationErrors.image.first, .missingImage)
        }
    }
    
    func test_campaignDetails_imageField_validImage_noValidationError() async {
        let mockImageData = Data(repeating: 0, count: 100)
        
        let store = TestStore(
            initialState: CampaignDetailsFeature.State(
                campaign: Campaign(id: .init(0), image: .init(raw: mockImageData), purpose: "Valid Name")
            )
        ) {
            CampaignDetailsFeature()
        } withDependencies: {
            $0.validationClient = .liveValue
        }
        store.exhaustivity = .off(showSkippedAssertions: false)
        
        await store.send(.onSaveButtonTapped)
        
        await store.assert {
            XCTAssertTrue($0.validationErrors.image.isEmpty)
            XCTAssertFalse($0.validationErrors.hasErrors(for: .image))
        }
    }
    
    func test_campaignDetails_imageField_fixedAfterError_clearsValidationError() async {
        let store = TestStore(
            initialState: CampaignDetailsFeature.State(
                campaign: Campaign(id: .init(0), image: nil, purpose: "Valid Name")
            )
        ) {
            CampaignDetailsFeature()
        } withDependencies: {
            $0.validationClient = .liveValue
        }
        store.exhaustivity = .off(showSkippedAssertions: false)
        
        await store.send(.onSaveButtonTapped)
        
        await store.assert {
            XCTAssertFalse($0.validationErrors.image.isEmpty)
            XCTAssertTrue($0.validationErrors.hasErrors(for: .image))
        }
        
        let mockImageData = Data(repeating: 0, count: 100)
        var updatedCampaign = store.state.campaign
        updatedCampaign.image = .init(raw: mockImageData)
        
        await store.send(.binding(.set(\.$campaign, updatedCampaign))) {
            $0.campaign.image = .init(raw: mockImageData)
        }
        
        await store.send(.validateForm)
        
        await store.assert {
            XCTAssertTrue($0.validationErrors.image.isEmpty)
            XCTAssertFalse($0.validationErrors.hasErrors(for: .image))
        }
    }
    
    func test_campaignDetails_templateField_missingTemplate_showsValidationError() async {
        let store = TestStore(
            initialState: CampaignDetailsFeature.State(
                campaign: Campaign(id: .init(0), image: Campaign.Image(raw: Data()), purpose: "Valid Name")
            )
        ) {
            CampaignDetailsFeature()
        } withDependencies: {
            $0.validationClient = .liveValue
        }
        store.exhaustivity = .off(showSkippedAssertions: false)
        
        await store.send(.onSaveButtonTapped)
        
        await store.assert {
            XCTAssertFalse($0.validationErrors.template.isEmpty)
            XCTAssertTrue($0.validationErrors.hasErrors(for: .template))
        }
    }
    
    func test_campaignDetails_templateField_validTemplate_noValidationError() async {
        let store = TestStore(
            initialState: CampaignDetailsFeature.State(
                campaign: Campaign(id: .init(0), image: Campaign.Image(raw: Data()), template: .init(name: "1", gradient: .angularYellowBlue, imagePlacement: .center), purpose: "Valid Name")
            )
        ) {
            CampaignDetailsFeature()
        } withDependencies: {
            $0.validationClient = .liveValue
        }
        store.exhaustivity = .off(showSkippedAssertions: false)
        
        await store.send(.onSaveButtonTapped)
        
        await store.assert {
            XCTAssertTrue($0.validationErrors.template.isEmpty)
        }
    }
    
    func test_campaignDetails_imagePreview_presentedOrHiddenByImageTap() async {
        let store = TestStore(
            initialState: CampaignDetailsFeature.State(
                campaign: Campaign(id: .init(0), image: Campaign.Image(raw: Data()))
            )
        ) {
            CampaignDetailsFeature()
        }
        
        store.exhaustivity = .off(showSkippedAssertions: false)
        
        await store.send(.onImageTapped)
        
        await store.assert {
            XCTAssertTrue($0.isPresentingImageOverlay)
        }
        
        await store.send(.onImageTapped)
        
        await store.assert {
            XCTAssertFalse($0.isPresentingImageOverlay)
        }
    }

    func test_campaignTemplate_presentedByTap() async {
        let campaign = Campaign(id: .init(0), image: Campaign.Image(raw: Data()), purpose: "Valid Name")
        let store = TestStore(
            initialState: CampaignDetailsFeature.State(
                campaign: campaign
            )
        ) {
            CampaignDetailsFeature()
        }
        
        store.exhaustivity = .off(showSkippedAssertions: false)
        
        await store.send(.onTemplateButtonTapped)
        
        store.assert {
            XCTAssertEqual($0.destination, .templateSelection(.init(campaign: campaign)))
        }
    }
    
    func test_campaignTemplate_hasNoSelectionAtStart() async {
        let store = TestStore(
            initialState: TemplateSelectionFeature.State(campaign: Campaign(id: .init(0), image: Campaign.Image(raw: Data()), purpose: "Valid Name"))
        ) {
            TemplateSelectionFeature()
        }
        
        store.exhaustivity = .off(showSkippedAssertions: false)
        
        store.assert {
            XCTAssertNil($0.selectedTemplateID)
        }
    }
    
    func test_campaignTemplate_hasSelectionForCampaignWithTemplate() async {
        let campaignWithTemplate = Campaign(id: .init(0), image: Campaign.Image(raw: Data()), template: Template(name: "1", gradient: .linearPurple, imagePlacement: .topCenter), purpose: "Valid Name")
        let store = TestStore(
            initialState: TemplateSelectionFeature.State(campaign: campaignWithTemplate)
        ) {
            TemplateSelectionFeature()
        }
        
        store.exhaustivity = .off(showSkippedAssertions: false)
        
        store.assert {
            XCTAssertNotNil($0.selectedTemplateID)
        }
    }
    
    func test_campaignTemplate_updatesCampaignTemplateOnSelectionAndConfirmation() async {
        let campaign = Campaign(id: .init(0), image: Campaign.Image(raw: Data()), purpose: "Valid Name")
        let store = TestStore(initialState: CampaignDetailsFeature.State(campaign: campaign, destination: .templateSelection(.init(campaign: campaign)))) {
            CampaignDetailsFeature()
        }
        
        store.exhaustivity = .off(showSkippedAssertions: false)
        
        let template = Template(name: "1", gradient: .linearPurple, imagePlacement: .topCenter)
        
        await store.send(.destination(.presented(.templateSelection(.templateSelected(template)))))
        await store.send(.destination(.presented(.templateSelection(.doneButtonTapped))))
        await store.skipReceivedActions()
        
        await store.assert {
            XCTAssertEqual($0.campaign.template?.id, template.id)
        }
    }
    
    func test_campaignDetails_onCampaignSave_rendersImageAndSavesItToPhotoLibrary() async {
        let campaign = Campaign.mock1
        var isPhotoSavedInLibrary = false
        var isCampaignImageRendered = false
        
        let store = TestStore(initialState: CampaignDetailsFeature.State(campaign: campaign)) {
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
        
        await store.assert { _ in
            XCTAssertTrue(isCampaignImageRendered)
            XCTAssertTrue(isPhotoSavedInLibrary)
        }
    }
    
    func test_campaignDetails_onCampaignSaveWithPhotoLibraryAccessDenied_presentsAlert() async {
        let campaign = Campaign.mock1
        var isSettingsOpened = false
        
        let store = TestStore(initialState: CampaignDetailsFeature.State(campaign: campaign)) {
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
        
        await store.assert {
            XCTAssertTrue($0.destination?.isAlert ?? false)
            XCTAssertFalse(isSettingsOpened)
        }
        
        await store.send(.destination(.presented(.alert(.openAppSettings))))
        
        await store.assert { _ in
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
