//
//  CampaignList.swift
//  MakeCampaign
//
//  Created by Andrii Solodkyi on 5/1/25.
//

import SwiftUI
import ComposableArchitecture

// MARK: - Main View

struct CampaignsView: View {
    @Bindable var store: StoreOf<CampaignsFeature>
    
    var body: some View {
        ZStack {
            CampaignsContentView(store: store)
            CampaignsFooterView(store: store)
        }
        .task {
            store.send(.onViewInitialLoad)
        }
        .sheet(item: $store.scope(state: \.addCampaign, action: \.addCampaign)) { store in
            NavigationStack {
                CampaignDetailsFormView(store: store)
                    .navigationTitle("Новий збір")
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarBackButtonHidden(true)
            }
        }
    }
}

// MARK: - Content View

private struct CampaignsContentView: View {
    let store: StoreOf<CampaignsFeature>
    
    var body: some View {
        if store.state.campaigns.isEmpty {
            EmptyStateView(store: store)
        } else {
            CampaignsGridView(store: store)
        }
    }
}

// MARK: - Empty State

private struct EmptyStateView: View {
    let store: StoreOf<CampaignsFeature>
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            EmptyStateHeaderView()
            EmptyStateCallToActionView(store: store)
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

private struct EmptyStateHeaderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "megaphone.fill")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.blue, Color.blue.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 8) {
                Text("Створіть свою першу обкладинку для збору коштів")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("Допомагайте тим, хто цього потребує")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
    }
}

private struct EmptyStateCallToActionView: View {
    let store: StoreOf<CampaignsFeature>
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Text("Натисніть")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(Color.blue))
                
                Text("щоб створити збір")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .onTapGesture {
                store.send(.createCampaignPlaceholderButtonTapped)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Campaigns Grid

private struct CampaignsGridView: View {
    let store: StoreOf<CampaignsFeature>
    
    private let columns = [
        GridItem(.flexible(minimum: 150, maximum: 200), spacing: 12),
        GridItem(.flexible(minimum: 150, maximum: 200), spacing: 12)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(store.state.campaigns.elements) { campaign in
                    CampaignCardView(
                        campaign: campaign,
                        onSelect: { campaignId in
                            store.send(.campaignSelected(campaignId))
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 120)
        }
    }
}

// MARK: - Footer (Floating Action Button)

private struct CampaignsFooterView: View {
    let store: StoreOf<CampaignsFeature>
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                FloatingActionButton {
                    store.send(.createCampaignButtonTapped)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 36)
            }
        }
    }
}

private struct FloatingActionButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
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
    }
}

// MARK: - Campaign Card

struct CampaignCardView: View {
    let campaign: Campaign
    let onSelect: (Campaign.ID) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            CampaignCardImageView(campaign: campaign)
            CampaignCardDetailsView(campaign: campaign)
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
        .onTapGesture {
            onSelect(campaign.id)
        }
    }
}

// MARK: - Campaign Card Image

private struct CampaignCardImageView: View {
    let campaign: Campaign
    
    var body: some View {
        if let imageData = campaign.image?.raw,
           let uiImage = UIImage(data: imageData) {
            CampaignImageContent(campaign: campaign, image: uiImage)
        } else {
            CampaignImagePlaceholder()
        }
    }
}

private struct CampaignImageContent: View {
    let campaign: Campaign
    let image: UIImage
    
    var body: some View {
        Group {
            if let template = campaign.template {
                CampaignTemplateView(campaign: campaign, template: template, image: image)
            } else {
                CampaignRawImage(image: image)
            }
        }
        .aspectRatio(1.0, contentMode: .fit)
        .clipped()
        .cornerRadius(12, corners: [.topLeft, .topRight])
    }
}

private struct CampaignRawImage: View {
    let image: UIImage
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Rectangle()
                    .fill(Color.black.opacity(0.05))
                
                Image(uiImage: image)
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

private struct CampaignImagePlaceholder: View {
    var body: some View {
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
}

// MARK: - Campaign Card Details

private struct CampaignCardDetailsView: View {
    let campaign: Campaign
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            CampaignPurposeText(purpose: campaign.purpose)
            CampaignMetricsView(campaign: campaign)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct CampaignPurposeText: View {
    let purpose: String
    
    var body: some View {
        Text(purpose)
            .font(.system(size: 15, weight: .semibold))
            .lineLimit(2)
            .multilineTextAlignment(.leading)
            .foregroundColor(.primary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct CampaignMetricsView: View {
    let campaign: Campaign
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            if let progress = campaign.progress {
                CampaignProgressView(progress: progress)
            }
            
            if let target = campaign.target {
                CampaignTargetRow(target: target)
            }
            
            if let collected = campaign.jar?.details?.amountInHryvnias {
                CampaignCollectedRow(collected: collected)
            }
        }
    }
}

private struct CampaignProgressView: View {
    let progress: Progress
    
    var body: some View {
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
}

private struct CampaignTargetRow: View {
    let target: Double
    
    var body: some View {
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
}

private struct CampaignCollectedRow: View {
    let collected: Double
    
    var body: some View {
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
    @Shared(.fileStorage(.campaigns)) var campaigns: IdentifiedArrayOf<Campaign> = Campaign.mocks
    
    CampaignsView(
        store: Store(
            initialState:
                CampaignsFeature.State()
        ) {
            CampaignsFeature()
                ._printChanges()
        })
}
