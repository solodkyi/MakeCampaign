//
//  CampaignList.swift
//  MakeCampaign
//
//  Created by Andrii Solodkyi on 5/1/25.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct CampaignsFeature: Reducer {
    struct State {
        var campaigns: IdentifiedArrayOf<Campaign> = []
        @PresentationState var addCampaign: CampaignDetailsFeature.State?
        @PresentationState var openCampaign: CampaignDetailsFeature.State?
    }
    
    enum Action {
        case createCampaignButtonTapped
        case campaignSelected(Campaign.ID)
        case cancelNewCampaignButtonTapped
        case saveNewCampaignButtonTapped
        case addCampaign(PresentationAction<CampaignDetailsFeature.Action>)
        case openCampaign(PresentationAction<CampaignDetailsFeature.Action>)
    }
    
    @Dependency(\.uuid) var uuid

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .createCampaignButtonTapped:
                state.addCampaign = .init(campaign: .init(id: self.uuid()))
                return .none
            case let .campaignSelected(campaignId):
                guard let campaign = state.campaigns[id: campaignId] else { return .none }
                
                state.openCampaign = .init(campaign: campaign)
                return .none
            case .addCampaign, .openCampaign:
                return .none
            case .cancelNewCampaignButtonTapped:
                state.addCampaign = nil
                return .none
            case .saveNewCampaignButtonTapped:
                guard let campaign = state.addCampaign?.campaign else { return .none }
                state.campaigns.append(campaign)
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

struct CampaignsView: View {
    let store: StoreOf<CampaignsFeature>
    
    var body: some View {
            WithViewStore(self.store, observe: \.campaigns) { viewStore in
                ZStack {
                    ScrollView {
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), alignment: .top),
                                GridItem(.flexible(), alignment: .top)
                            ]) {
                            ForEach(viewStore.state.elements) { element in
                                CampaignCardView(campaign: element)
                                    .padding(.top)
                                    .onTapGesture {
                                        viewStore.send(.campaignSelected(element.id))
                                    }
                            }
                        }
                        .padding()
                    }
                    VStack {
                        Spacer()
                            Button {
                                viewStore.send(.createCampaignButtonTapped)
                            } label: {
                                Image(systemName: "plus")
                                    .resizable()
                                    .foregroundStyle(.white)
                                    .padding(20)
                                    .background(Circle().fill(Color.blue))
                                    .frame(width: 70, height: 70)
                            }
                            .padding()
                    }
                .sheet(store: self.store.scope(
                    state: \.$addCampaign,
                    action: \.addCampaign
                )) { store in
                    NavigationStack {
                        CampaignDetailsFormView(store: store)
                            .navigationTitle("Новий збір")
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    Button("Закрити") {
                                        viewStore.send(.cancelNewCampaignButtonTapped)
                                    }
                                }
                                ToolbarItem {
                                    Button("Зберегти") {
                                        viewStore.send(.saveNewCampaignButtonTapped)
                                    }
                                }
                            }
                    }
                }
            }
        }
    }
}

struct CampaignCardView: View {
    let campaign: Campaign
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let imageData = campaign.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 140)
                    .clipped()
                    .cornerRadius(12, corners: [.topLeft, .topRight])
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(campaign.purpose)
                    .font(.headline)
                if let target = campaign.target {
                    Text("Ціль: \(target.currencyFormatted) грн.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                if let collected = campaign.collected {
                    Text("\(collected.currencyFormatted) грн.")
                        .font(.subheadline)
                        .bold()
                }
                if let progress = campaign.progress {
                    ProgressView(value: progress.fractionCompleted)
                }
            }
            .padding([.horizontal, .bottom])
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    CampaignsView(
        store: Store(
            initialState:
                CampaignsFeature.State(
                    campaigns: Campaign.mocks)
        ) {
        CampaignsFeature()
                ._printChanges()
    })
}
