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
}
