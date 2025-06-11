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
        case templateSelection(TemplateSelectionFeature)
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
            case let .campaignsList(.delegate(.onCampaignSelected(campaignId))):
                guard let campaign = state.campaignsList.$campaigns[id: campaignId] else {
                    return .none
                }
                state.path.append(.details(.init(campaign: campaign, isEditing: true)))
                
                return .none
                default: return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}
