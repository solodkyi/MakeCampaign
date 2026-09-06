//
//  PurpleGradientTemplateView.swift
//  MakeCampaign
//

import SwiftUI

/// `linearPurple_topCenter` — the photo runs full bleed across the top under a
/// deepening plum scrim, with the campaign data set on solid plum beneath it.
///
/// The scrim is what makes the seam between photo and panel read as one surface,
/// so it darkens to nearly the panel colour at its foot.
struct PurpleGradientTemplateView: View {
    let purpose: String
    let goal: String?

    var viewProvider: () -> AnyView

    init(purpose: String, goal: String?, viewProvider: @escaping () -> some View = { Color.clear }) {
        self.purpose = purpose
        self.goal = goal
        self.viewProvider = { AnyView(viewProvider()) }
    }

    var body: some View {
        GeometryReader { geometry in
            let side = geometry.size.width

            VStack(spacing: 0) {
                photo
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                caption(side: side)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(Self.plum)
        }
    }

    private var photo: some View {
        PosterPhoto(Rectangle(), photo: viewProvider)
            .overlay {
                LinearGradient(
                    colors: [Self.plum.opacity(0.25), Self.plum.opacity(0.85)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)
            }
    }

    private func caption(side: CGFloat) -> some View {
        let purposeSize = side * 0.056

        return VStack(alignment: .leading, spacing: side * 0.03) {
            Text(purpose)
                .campaignPosterElement(.campaignTitle)
                .font(PosterFont.oswaldMedium.size(purposeSize))
                .lineSpacing(purposeSize * 0.08)
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let goal {
                let labelSize = side * 0.023

                HStack(alignment: .firstTextBaseline, spacing: side * 0.03) {
                    Text("ціль збору:")
                        .font(PosterFont.plexMonoRegular.size(labelSize))
                        .tracking(labelSize * 0.2)
                        .textCase(.uppercase)
                        .foregroundStyle(Self.lilac)

                    Text(goal)
                        .campaignPosterElement(.target)
                        .font(PosterFont.oswaldBold.size(side * 0.08))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                .padding(.top, side * 0.03)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(.white.opacity(0.35))
                        .frame(height: side * 0.002)
                }
            }
        }
        .padding(.horizontal, side * 0.06)
        .padding(.top, side * 0.05)
        .padding(.bottom, side * 0.06)
    }

    private static let plum = Color(red: 43/255, green: 17/255, blue: 80/255)
    private static let lilac = Color(red: 201/255, green: 166/255, blue: 255/255)
}

#Preview {
    PosterTemplatePreview { purpose, goal, photo in
        PurpleGradientTemplateView(purpose: purpose, goal: goal, viewProvider: photo)
    }
}
