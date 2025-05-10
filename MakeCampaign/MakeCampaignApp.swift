//
//  MakeCampaignApp.swift
//  MakeCampaign
//
//  Created by Andrii Solodkyi on 5/1/25.
//

import SwiftUI
import ComposableArchitecture

struct AppFeature: Reducer {
    struct State {
        var path = StackState<Path.State>()
        var campaignsList = CampaignsFeature.State()
    }
    
    enum Action {
        case path(StackAction<Path.State, Path.Action>)
        case campaignsList(CampaignsFeature.Action)
    }
    
    struct Path: Reducer {
        enum State {
            case details(CampaignDetailsFeature.State)
            case templateSelection(TemplateSelectionFeature.State)
        }
        
        enum Action {
            case details(CampaignDetailsFeature.Action)
            case templateSelection(TemplateSelectionFeature.Action)
        }
        
        var body: some ReducerOf<Self> {
            Scope(state: /State.details, action: /Action.details, child: {
                CampaignDetailsFeature()
            })
            Scope(state: /State.templateSelection, action: /Action.templateSelection, child: {
                TemplateSelectionFeature()
            })
        }
    }
    
    var body: some ReducerOf<Self> {
        Scope(
            state: \.campaignsList,
            action: /Action.campaignsList) {
                CampaignsFeature()
            }
        
        Reduce { state, action in
            switch action {
            case let .path(.element(id: id, action: .details(.delegate(action)))):
                switch action {
                case let .campaignUpdated(campaign):
                    state.campaignsList.campaigns[id: campaign.id] = campaign
                    return .none
                case let .deleteCampaign(campaignId):
                    state.campaignsList.campaigns.remove(id: campaignId)
                    return .none
                case let .didSelectImage(data, campaignId):
                    state.campaignsList.campaigns[id: campaignId]?.imageData = data
                    state.path[id: id, case: /Path.State.details]?.campaign.imageData = data
                    return .none
                }
            case let .path(.element(id, action: .templateSelection(.delegate(action)))):
                switch action {
                case let .templateApplied(template, campaignId):
                    guard let detailsId = state.path.ids.dropLast().last else { return .none }
                    state.path[id: detailsId, case: /Path.State.details]?.campaign.template = template
                    state.campaignsList.campaigns[id: campaignId]?.template = template
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
        .forEach(\.path, action: /Action.path) {
            Path()
        }
    }
}

struct AppView: View {
    let store: StoreOf<AppFeature>
    
    var body: some View {
        NavigationStackStore(
            self.store.scope(state: \.path, action: { .path($0) })
        ) {
            CampaignsView(
                store: self.store.scope(
                    state: \.campaignsList,
                    action: { .campaignsList($0) }
                )
            )
            .navigationTitle("Збори")
        } destination: { state in
            switch state {
            case .details:
                CaseLet(
                    /AppFeature.Path.State.details,
                     action: AppFeature.Path.Action.details) { store in
                    CampaignDetailsFormView(store: store)
                }
            case .templateSelection:
                CaseLet(
                    /AppFeature.Path.State.templateSelection,
                     action: AppFeature.Path.Action.templateSelection) { store in
                    TemplateSelectionView(store: store)
                }
            }
        }
    }
}

#Preview {
    AppView(store: .init(initialState: AppFeature.State(), reducer: {
        AppFeature()
            ._printChanges()
    }))
}

@main
struct MakeCampaignApp: App {
    var body: some Scene {
        WindowGroup {
            AppView(store: .init(initialState: AppFeature.State(campaignsList: .init(campaigns: [.mock1, .mock2])), reducer: {
                AppFeature()
                    ._printChanges()
            }))
        }
    }
}
