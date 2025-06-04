//
//  CampaignList.swift
//  MakeCampaign
//
//  Created by Andrii Solodkyi on 5/1/25.
//

import SwiftUI
import ComposableArchitecture

struct CampaignsView: View {
    @Perception.Bindable var store: StoreOf<CampaignsFeature>
    
    var body: some View {
        WithPerceptionTracking {
            ZStack {
                if store.state.campaigns.isEmpty {
                    VStack(spacing: 24) {
                        Spacer()
                        
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
                        
                        VStack(spacing: 12) {
                            HStack(spacing: 8) {
                                Text("Натисніть")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                Image(systemName: "plus")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 24, height: 24)
                                    .background(
                                        Circle()
                                            .fill(Color.blue)
                                    )
                                
                                Text("щоб створити збір")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            .onTapGesture(perform: {
                                store.send(.createCampaignPlaceholderButtonTapped)
                            })
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
                        
                        Spacer()
                    }
                    .padding(.horizontal, 32)
                } else {
                    ScrollView {
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(minimum: 150, maximum: 200), spacing: 12),
                                GridItem(.flexible(minimum: 150, maximum: 200), spacing: 12)
                            ],
                            spacing: 16
                        ) {
                            ForEach(store.state.campaigns.elements) { element in
                                CampaignCardView(campaign: element, onSelect: { campaignId in
                                    store.send(.campaignSelected(campaignId))
                                })
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 120)
                    }
                }
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            store.send(.createCampaignButtonTapped)
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
}

struct CampaignCardView: View {
    let campaign: Campaign
    let onSelect: (Campaign.ID) -> Void
    
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
        .onTapGesture {
            onSelect(campaign.id)
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
    CampaignsView(
        store: Store(
            initialState:
                CampaignsFeature.State()
        ) {
        CampaignsFeature()
                ._printChanges()
    })
}
