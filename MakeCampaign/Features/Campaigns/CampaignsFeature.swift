//
//  CampaignsFeature.swift
//  MakeCampaign
//
//  Created by andriisolodkyi on 29.05.2025.
//
import SwiftUI
import ComposableArchitecture

extension PersistenceKey where Self == PersistenceKeyDefault<FileStorageKey<IdentifiedArrayOf<Campaign>>> {
    static var campaigns: Self {
        PersistenceKeyDefault(.fileStorage(.campaigns), [])
    }
}

@Reducer
struct CampaignsFeature {
    @ObservableState
    struct State: Equatable {
        @Shared(.campaigns) var campaigns
        @Presents var addCampaign: CampaignDetailsFeature.State?
    }
    
    enum Action {
        case onViewInitialLoad
        case createCampaignButtonTapped
        case createCampaignPlaceholderButtonTapped
        case campaignSelected(Campaign.ID)
        case cancelNewCampaignButtonTapped
        case addCampaign(PresentationAction<CampaignDetailsFeature.Action>)
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
            case .onViewInitialLoad:
    
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
            case let .campaignSelected(id):
                return .send(.delegate(.onCampaignSelected(id)))
            case let .onCampaignJarDetailsLoaded(campaignId, jarDetails):
                state.campaigns[id: campaignId]?.jar?.details = jarDetails
                return .none
            case .createCampaignButtonTapped, .createCampaignPlaceholderButtonTapped:
                state.addCampaign = .init(campaign: Shared(.init(id: self.uuid())))
                return .none
            case .addCampaign, .delegate:
                return .none
            case .cancelNewCampaignButtonTapped:
                state.addCampaign = nil
                return .none
            }
        }
        .ifLet(\.$addCampaign, action: \.addCampaign) {
            CampaignDetailsFeature()
        }
    }
}
