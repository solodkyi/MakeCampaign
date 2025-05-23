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
            case .createCampaignButtonTapped:
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
                if let index = state.campaigns.firstIndex(where: { $0.id == campaign.id }) {
                    state.campaigns[index] = campaign
                }
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

struct CampaignsView: View {
    let store: StoreOf<CampaignsFeature>
    
    var body: some View {
        WithViewStore(self.store, observe: \.campaigns) { viewStore in
            ZStack {
                ScrollView {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(minimum: 150, maximum: 200), spacing: 12),
                            GridItem(.flexible(minimum: 150, maximum: 200), spacing: 12)
                        ],
                        spacing: 16
                    ) {
                        ForEach(viewStore.state.elements) { element in
                            CampaignCardView(campaign: element)
                                .onTapGesture {
                                    viewStore.send(.campaignSelected(element.id))
                                }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 120) // Space for floating button
                }
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            viewStore.send(.createCampaignButtonTapped)
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 56, height: 56)
                                .background(
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.blue, Color.blue.opacity(0.8)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .shadow(color: .blue.opacity(0.3), radius: 12, x: 0, y: 6)
                                )
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 36)
                    }
                }
            }
            .task {
                viewStore.send(.onViewInitialLoad)
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
                        }
                }
            }
        }
    }
}

struct CampaignCardView: View {
    let campaign: Campaign
    
    var body: some View {
        VStack(spacing: 0) {
            if let imageData = campaign.image?.raw,
               let uiImage = UIImage(data: imageData) {
                Group {
                    if let template = campaign.template {
                        CampaignTemplateView(campaign: campaign, template: template, image: uiImage)
                    } else {
                        GeometryReader { geometry in
                            ZStack {
                                Rectangle()
                                    .fill(Color.black.opacity(0.05))
                                
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(
                                        width: geometry.size.width,
                                        height: geometry.size.height
                                    )
                                    .clipped()
                            }
                            .frame(
                                width: geometry.size.width,
                                height: geometry.size.height
                            )
                        }
                    }
                }
                .aspectRatio(1.0, contentMode: .fit) // Square aspect ratio for templates
                .clipped()
                .cornerRadius(12, corners: [.topLeft, .topRight])
            } else {
                // Placeholder when no image
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .aspectRatio(1.0, contentMode: .fit)
                    .cornerRadius(12, corners: [.topLeft, .topRight])
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "photo")
                                .font(.system(size: 32, weight: .light))
                                .foregroundColor(.gray)
                            Text("Немає зображення")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.gray)
                        }
                    )
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(campaign.purpose)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                
                VStack(alignment: .leading, spacing: 3) {
                    if let progress = campaign.progress {
                        VStack(spacing: 2) {
                            HStack {
                                Text("Прогрес")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(Int(progress.fractionCompleted * 100))%")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.blue)
                            }
                            
                            ProgressView(value: progress.fractionCompleted)
                                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                                .scaleEffect(x: 1, y: 0.8)
                        }
                    }
                    
                    if let target = campaign.target {
                        HStack {
                            Text("Ціль:")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(target.formattedAmount.appendingCurrency)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let collected = campaign.jar?.details?.amountInHryvnias {
                        HStack {
                            Text("Зібрано:")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(collected.formattedAmount.appendingCurrency)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
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
                CampaignsFeature.State()
        ) {
        CampaignsFeature()
                ._printChanges()
    })
}
