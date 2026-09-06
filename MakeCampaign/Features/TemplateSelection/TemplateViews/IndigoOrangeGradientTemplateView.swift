//
//  IndigoOrangeGradientTemplateView.swift
//  MakeCampaign
//

import SwiftUI

/// `linearIndigoOrange_trailing` — flat orange ground, the photo cut to an arch
/// rising off the trailing edge, and the campaign data on an indigo panel.
///
/// The arch is a half-width radius on the top corners only, so it stays a true
/// semicircle whatever the poster ratio.
struct IndigoOrangeGradientTemplateView: View {
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
            let photoWidth = side * 0.68

            VStack(alignment: .leading, spacing: side * 0.035) {
                kicker(side: side)

                PosterPhoto(UnevenRoundedRectangle( topLeadingRadius: photoWidth / 2, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: photoWidth / 2 ), photo: viewProvider)
                    .frame(width: photoWidth)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .frame(maxHeight: .infinity)

                panel(side: side)
            }
            .padding(side * 0.06)
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(Self.tangerine)
        }
    }

    private func kicker(side: CGFloat) -> some View {
        let size = side * 0.023

        return Text("збір")
            .font(PosterFont.plexMonoRegular.size(size))
            .tracking(size * 0.32)
            .textCase(.uppercase)
            .foregroundStyle(Self.indigo)
    }

    private func panel(side: CGFloat) -> some View {
        let purposeSize = side * 0.05

        return VStack(alignment: .leading, spacing: side * 0.02) {
            Text(purpose)
                .campaignPosterElement(.campaignTitle)
                .font(PosterFont.oswaldSemiBold.size(purposeSize))
                .lineSpacing(purposeSize * 0.08)
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let goal {
                let labelSize = side * 0.022

                HStack(alignment: .firstTextBaseline, spacing: side * 0.022) {
                    Text("ціль збору:")
                        .font(PosterFont.plexMonoRegular.size(labelSize))
                        .tracking(labelSize * 0.16)
                        .textCase(.uppercase)
                        .foregroundStyle(Self.apricot)

                    Text(goal)
                        .campaignPosterElement(.target)
                        .font(PosterFont.oswaldBold.size(side * 0.066))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                .padding(.top, side * 0.02)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(.white.opacity(0.4))
                        .frame(height: side * 0.002)
                }
            }
        }
        .padding(.horizontal, side * 0.034)
        .padding(.vertical, side * 0.03)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Self.indigo)
    }

    private static let tangerine = Color(red: 239/255, green: 115/255, blue: 38/255)
    private static let indigo = Color(red: 36/255, green: 33/255, blue: 94/255)
    private static let apricot = Color(red: 255/255, green: 179/255, blue: 122/255)
}

#Preview {
    PosterTemplatePreview { purpose, goal, photo in
        IndigoOrangeGradientTemplateView(purpose: purpose, goal: goal, viewProvider: photo)
    }
}
