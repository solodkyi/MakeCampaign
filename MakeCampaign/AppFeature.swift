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
    struct State: Equatable {
        var path = StackState<Path.State>()
        var campaignsList = CampaignsFeature.State()
    }
    
    enum Action {
        case path(StackAction<Path.State, Path.Action>)
        case campaignsList(CampaignsFeature.Action)
    }
    
    @Reducer
    struct Path {

        enum State: Equatable {
            case details(CampaignDetailsFeature.State)
            case templateSelection(TemplateSelectionFeature.State)
        }
        
        enum Action {
            case details(CampaignDetailsFeature.Action)
            case templateSelection(TemplateSelectionFeature.Action)
        }
        
        var body: some ReducerOf<Self> {
            Scope(state: \.details, action: \.details, child: {
                CampaignDetailsFeature()
            })
            Scope(state: \.templateSelection, action: \.templateSelection, child: {
                TemplateSelectionFeature()
            })
        }
    }
    
    @Dependency(\.continuousClock) var clock
    @Dependency(\.dataManager.save) var saveData
    
    var body: some ReducerOf<Self> {
        Scope(
            state: \.campaignsList,
            action: \.campaignsList) {
                CampaignsFeature()
            }
        
        Reduce { state, action in
            switch action {
            case let .path(.element(id: id, action: .details(.delegate(action)))):
                switch action {
                case let .deleteCampaign(campaignId):
                    state.campaignsList.campaigns.remove(id: campaignId)
                    return .none
                case let .saveCampaign(campaign):
                    state.campaignsList.campaigns[id: campaign.id] = campaign
                    state.path[id: id, case: \.details]?.campaign = campaign
                    
                    return .none
                }
            case let .path(.element(id: _, action: .details(.destination(.presented(.templateSelection(.delegate(action))))))):
                switch action {
                case let .templateApplied(template, campaignId):
                    state.campaignsList.campaigns[id: campaignId]?.template = template
                    return .none
                case let .imageRepositioned(scale, offset, containerSize, campaignId):
                    guard var campaign = state.campaignsList.campaigns[id: campaignId] else { return .none }
                    campaign.imageOffset = offset
                    campaign.imageScale = scale
                    campaign.imageReferenceSize = containerSize
                    state.campaignsList.campaigns[id: campaignId] = campaign
                    return .none
                }
            case .path: return .none
            case let .campaignsList(action):
                switch action {
                case let .campaignSelected(campaignId):
                    guard let campaign = state.campaignsList.campaigns[id: campaignId] else {
                        return .none
                    }
                    state.path.append(.details(.init(campaign: campaign,  isEditing: true)))
                default: break
                }
                return .none
            }
        }
        .forEach(\.path, action: \.path) {
            Path()
        }
        Reduce { state, _ in
            .run { [campaigns = state.campaignsList.campaigns] _ in
                enum CancelID { case saveDebounce }
                
                try await withTaskCancellation(id: CancelID.saveDebounce, cancelInFlight: true) {
                    try await self.clock.sleep(for: .seconds(1))
                    try self.saveData(JSONEncoder().encode(campaigns), .campaigns)
                }
            }
        }
    }
}
