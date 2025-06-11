//
//  MakeCampaignApp.swift
//  MakeCampaign
//
//  Created by Andrii Solodkyi on 5/1/25.
//

import SwiftUI
import ComposableArchitecture

struct AppView: View {
    @Perception.Bindable var store: StoreOf<AppFeature>
    
    var body: some View {
        WithPerceptionTracking {
            NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
                CampaignsView(
                    store: self.store.scope(
                        state: \.campaignsList,
                        action: \.campaignsList
                    )
                )
                .navigationTitle("Збори")
            } destination: { store in
                switch store.case {
                case let .details(store):
                    CampaignDetailsFormView(store: store)
                case let .templateSelection(store):
                    TemplateSelectionView(store: store)
                }
            }
        }
    }
}

extension URL {
    static let campaigns = Self.documentsDirectory.appending(component: "campaigns.json")
}

#Preview {
    AppView(store: .init(initialState: AppFeature.State(), reducer: {
        AppFeature()
            ._printChanges()
    }, withDependencies: {
        $0.defaultFileStorage = .inMemory
    } ))
}

@main
struct MakeCampaignApp: App {
    var body: some Scene {
        WindowGroup {
            AppView(store: .init(initialState: AppFeature.State(campaignsList: .init())) {
                AppFeature()
                    ._printChanges()
            })
        }
    }
}
