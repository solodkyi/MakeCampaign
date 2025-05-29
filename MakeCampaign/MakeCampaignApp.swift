//
//  MakeCampaignApp.swift
//  MakeCampaign
//
//  Created by Andrii Solodkyi on 5/1/25.
//

import SwiftUI
import ComposableArchitecture

struct AppView: View {
    let store: StoreOf<AppFeature>
    
    var body: some View {
        NavigationStackStore(
            self.store.scope(state: \.path, action: { .path($0) })
        ) {
            CampaignsView(
                store: self.store.scope(
                    state: \.campaignsList,
                    action: \.campaignsList
                )
            )
            .navigationTitle("Збори")
        } destination: { store in
            WithViewStore(store, observe: { $0 }) { viewStore in
                switch viewStore.state {
                case let .details(detailsState):
                    CampaignDetailsFormView(store: store.scope(
                        state: { _ in detailsState },
                        action: { .details($0) }
                    ))
                case let .templateSelection(templateState):
                    TemplateSelectionView(store: store.scope(
                        state: { _ in templateState },
                        action: { .templateSelection($0) }
                    ))
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
        $0.dataManager = .mock(initialData: try? JSONEncoder().encode(Campaign.mocks))
    } ))
}

@main
struct MakeCampaignApp: App {
    var body: some Scene {
        WindowGroup {
            AppView(store: .init(initialState: AppFeature.State(campaignsList: .init()), reducer: {
                AppFeature()
            }))
        }
    }
}
