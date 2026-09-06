//
//  AppFeature.swift
//  MakeCampaign
//
//  Created by andriisolodkyi on 29.05.2025.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct AppFeature {
    @Dependency(\.uuid) var uuid
    @Dependency(\.date.now) var now

    @ObservableState
    struct State: Equatable {
        var path = StackState<Path.State>()
        var campaignsList = CampaignsFeature.State()
    }
    
    enum Action {
        case path(StackAction<Path.State, Path.Action>)
        case campaignsList(CampaignsFeature.Action)
    }
    
    @Reducer(state: .equatable)
    enum Path {
        case details(CampaignDetailsFeature)
        case editor(CampaignCreationFeature)
    }
        
    var body: some ReducerOf<Self> {
        Scope(
            state: \.campaignsList,
            action: \.campaignsList) {
                CampaignsFeature()
            }
        
        Reduce { state, action in
            switch action {
            case .path: return .none
            case .campaignsList(.createCampaignTapped):
                state.path.append(.editor(.init(
                    campaign: Campaign(
                        id: uuid(),
                        status: .draft,
                        createdAt: now,
                        updatedAt: now
                    ),
                    campaigns: state.campaignsList.$campaigns,
                    isNew: true
                )))
                return .none
            case let .campaignsList(.delegate(.onCampaignSelected(campaignId))):
                guard let campaign = state.campaignsList.campaigns[id: campaignId] else {
                    return .none
                }
                state.path.append(.editor(.init(
                    campaign: campaign,
                    campaigns: state.campaignsList.$campaigns,
                    isNew: false
                )))
                
                return .none
                default: return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}
