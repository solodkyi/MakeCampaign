//
//  MakeCampaignApp.swift
//  MakeCampaign
//
//  Created by Andrii Solodkyi on 5/1/25.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct AppFeature: Reducer {
    struct State {
        var path = StackState<Path.State>()
        var campaignsList = CampaignsFeature.State()
    }
    
    enum Action {
        case path(StackAction<Path.State, Path.Action>)
        case campaignsList(CampaignsFeature.Action)
    }
    
    @Reducer
    struct Path: Reducer {
        enum State {
            case details(CampaignDetailsFeature.State)
        }
        
        enum Action {
            case details(CampaignDetailsFeature.Action)
        }
        
        var body: some ReducerOf<Self> {
            Scope(state: \.details, action: \.details, child: {
                CampaignDetailsFeature()
            })
        }
    }
    
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
                case let .campaignUpdated(campaign):
                    state.campaignsList.campaigns[id: campaign.id] = campaign
                    return .none
                case let .campaignDeleted(campaignId):
                    state.campaignsList.campaigns.remove(id: campaignId)
                    state.path.pop(from: id)
                    return .none
                }
            case .path: return .none
            case let .campaignsList(action):
                switch action {
                case .campaignSelected(let campaignId):
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
    }
}

struct AppView: View {
    let store: StoreOf<AppFeature>
    
    var body: some View {
        NavigationStackStore(
            self.store.scope(state: \.path, action: \.path)
        ) {
            CampaignsView(
                store: self.store.scope(
                    state: \.campaignsList,
                    action: \.campaignsList
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
