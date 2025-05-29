//
//  CampaignsFeature.swift
//  MakeCampaign
//
//  Created by andriisolodkyi on 29.05.2025.
//
import SwiftUI
import ComposableArchitecture

@Reducer
struct CampaignsFeature {
    struct State: Equatable {
        var campaigns: IdentifiedArrayOf<Campaign> = []
        @PresentationState var addCampaign: CampaignDetailsFeature.State?
        @PresentationState var openCampaign: CampaignDetailsFeature.State?
        
        init(addCampaign: CampaignDetailsFeature.State? = nil, openCampaign: CampaignDetailsFeature.State? = nil) {
            do {
                @Dependency(\.dataManager.load) var loadData
                self.campaigns = try JSONDecoder().decode(IdentifiedArrayOf<Campaign>.self, from: loadData(.campaigns))
            } catch {
                self.campaigns = []
            }
            self.addCampaign = addCampaign
            self.openCampaign = openCampaign
        }
    }
    
    enum Action {
        case onViewInitialLoad
        case createCampaignButtonTapped
        case createCampaignPlaceholderButtonTapped
        case campaignSelected(Campaign.ID)
        case cancelNewCampaignButtonTapped
        case addCampaign(PresentationAction<CampaignDetailsFeature.Action>)
        case openCampaign(PresentationAction<CampaignDetailsFeature.Action>)
        case onCampaignJarDetailsLoaded(Campaign.ID, JarDetails?)
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
            case let .onCampaignJarDetailsLoaded(campaignId, jarDetails):
                state.campaigns[id: campaignId]?.jar?.details = jarDetails
                return .none
            case .createCampaignButtonTapped, .createCampaignPlaceholderButtonTapped:
                state.addCampaign = .init(campaign: .init(id: self.uuid()))
                return .none
            case let .campaignSelected(campaignId):
                guard let campaign = state.campaigns[id: campaignId] else { return .none }
                
                state.openCampaign = .init(campaign: campaign, isEditing: true)
                return .none
            case let .addCampaign(.presented(.delegate(.saveCampaign(campaign)))):
                state.campaigns.append(campaign)
                state.addCampaign = nil
                return .none
            case let .openCampaign(.presented(.delegate(.saveCampaign(campaign)))):
                state.campaigns[id: campaign.id] = campaign
                state.openCampaign = nil
                return .none
            case let .openCampaign(.presented(.delegate(.deleteCampaign(id)))):
                state.campaigns.remove(id: id)
                state.openCampaign = nil
                return .none
            case .addCampaign, .openCampaign:
                return .none
            case .cancelNewCampaignButtonTapped:
                state.addCampaign = nil
                return .none
            }
        }
        .ifLet(\.$addCampaign, action: \.addCampaign) {
            CampaignDetailsFeature()
        }
        .ifLet(\.$openCampaign, action: \.openCampaign) {
            CampaignDetailsFeature()
        }
    }
}
