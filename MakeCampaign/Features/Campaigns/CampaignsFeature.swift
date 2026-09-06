//
//  CampaignsFeature.swift
//  MakeCampaign
//
//  Created by andriisolodkyi on 29.05.2025.
//
import SwiftUI
import ComposableArchitecture
import Sharing

extension SharedKey where Self == FileStorageKey<IdentifiedArrayOf<Campaign>>.Default {
    static var campaigns: Self {
        Self[.fileStorage(.campaigns), default: []]
    }
}

@Reducer
struct CampaignsFeature {
    enum Section: String, CaseIterable, Equatable, Identifiable {
        case active
        case drafts

        var id: Self { self }
        var title: String { self == .active ? "Активні" : "Чернетки" }
    }

    enum JarPresentation: Equatable {
        case noLink
        case loading
        case failed
        case loaded

        var message: String {
            switch self {
            case .noLink:
                "Банку не підключено"
            case .loading:
                "Оновлюємо дані…"
            case .failed:
                "Не вдалося оновити"
            case .loaded:
                ""
            }
        }
    }

    @ObservableState
    struct State: Equatable {
        @Shared var campaigns: IdentifiedArrayOf<Campaign>
        var selectedSection: Section = .active
        var jarPresentations: [Campaign.ID: JarPresentation] = [:]

        init(campaigns: Shared<IdentifiedArrayOf<Campaign>>? = nil) {
            if let campaigns {
                self._campaigns = campaigns
            } else {
                self._campaigns = Shared(.campaigns)
            }
        }

        var visibleCampaigns: [Campaign] {
            campaigns.filter { campaign in
                switch selectedSection {
                case .active: campaign.status == .active
                case .drafts: campaign.status == .draft
                }
            }
        }

        func jarPresentation(for campaign: Campaign) -> JarPresentation {
            guard campaign.jar?.link != nil else { return .noLink }
            return jarPresentations[campaign.id] ?? .loading
        }
    }
    
    enum Action {
        case onViewInitialLoad
        case createCampaignTapped
        case sectionSelected(Section)
        case campaignSelected(Campaign.ID)
        case editCampaign(Campaign.ID)
        case deleteCampaignConfirmed(Campaign.ID)
        case onCampaignJarDetailsLoaded(Campaign.ID, JarDetails?)
        case delegate(Delegate)
        
        @CasePathable
        enum Delegate {
            case onCampaignSelected(Campaign.ID)
        }
    }
    
    @Dependency(\.uuid) var uuid
    @Dependency(\.jarApiClient) var apiClient
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .createCampaignTapped:
                return .none
            case let .sectionSelected(section):
                state.selectedSection = section
                return .none
            case .onViewInitialLoad:
                for campaign in state.campaigns where campaign.jar?.link != nil {
                    state.jarPresentations[campaign.id] = .loading
                }
    
                return .run { [campaigns = state.campaigns] send in
                    let campaignsWithLinks = campaigns.filter { $0.jar?.link != nil }

                    await withTaskGroup(of: (Campaign.ID, JarDetails?).self) { group in
                        for campaign in campaignsWithLinks {
                            group.addTask {
                                guard let jarLink = campaign.jar?.link else {
                                    return (campaign.id, nil)
                                }
                                do {
                                    let details = try await apiClient.loadProgress(jarLink)
                                    return (campaign.id, details)
                                } catch {
                                    return (campaign.id, nil)
                                }
                            }
                        }
                        
                        for await (campaignId, jarDetails) in group {
                            await send(.onCampaignJarDetailsLoaded(campaignId, jarDetails))
                        }
                    }
                }
            case let .campaignSelected(id), let .editCampaign(id):
                return .send(.delegate(.onCampaignSelected(id)))
            case let .onCampaignJarDetailsLoaded(campaignId, jarDetails):
                state.$campaigns.withLock {
                    $0[id: campaignId]?.jar?.details = jarDetails
                    if jarDetails != nil {
                        $0[id: campaignId]?.markUpdated()
                    }
                }
                state.jarPresentations[campaignId] = jarDetails == nil ? .failed : .loaded
                return .none
            case let .deleteCampaignConfirmed(id):
                state.$campaigns.withLock {
                    $0.remove(id: id)
                }
                state.jarPresentations[id] = nil
                return .none
            case .delegate:
                return .none
            }
        }
    }
}
