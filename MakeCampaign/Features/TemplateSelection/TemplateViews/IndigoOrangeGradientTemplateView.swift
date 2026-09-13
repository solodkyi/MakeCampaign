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
    let funding: CampaignPosterFunding

    var viewProvider: () -> AnyView

    init(
        purpose: String,
        funding: CampaignPosterFunding,
        viewProvider: @escaping () -> some View = { Color.clear }
    ) {
        self.purpose = purpose
        self.funding = funding
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

            if funding.isFinished {
                finished(side: side)
            } else if let goal = funding.goal {
                collecting(goal: goal, side: side)
            }
        }
        .padding(.horizontal, side * 0.034)
        .padding(.vertical, side * 0.03)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Self.indigo)
    }

    private func collecting(goal: String, side: CGFloat) -> some View {
        let labelSize = side * 0.030

        return VStack(alignment: .leading, spacing: side * 0.02) {
            VStack(alignment: .leading, spacing: side * 0.008) {
                HStack(alignment: .firstTextBaseline, spacing: side * 0.022) {
                    Text(funding.goalLabel)
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

                if let supportingGoal = funding.supportingGoal {
                    Text(supportingGoal)
                        .font(PosterFont.plexMonoRegular.size(labelSize * 0.86))
                        .foregroundStyle(Self.apricot.opacity(0.82))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }

            if let fraction = funding.fraction {
                progress(fraction: fraction, side: side)
            }
        }
        .modifier(PanelRule(side: side))
    }

    /// На індиговій панелі смужка світиться мандариновим — кольором самого
    /// тла, наче поступ витягує його всередину.
    private func progress(fraction: Double, side: CGFloat) -> some View {
        let labelSize = side * 0.027

        return VStack(alignment: .leading, spacing: side * 0.01) {
            PosterProgressBar(
                fraction: fraction,
                height: side * 0.012,
                track: .white.opacity(0.16),
                fill: Self.tangerine
            )

            if let collected = funding.collected {
                Text("зібрано \(collected)")
                    .campaignPosterFundingElement(.collected)
                    .font(PosterFont.plexMonoRegular.size(labelSize))
                    .tracking(labelSize * 0.14)
                    .textCase(.uppercase)
                    .foregroundStyle(Self.apricot)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
    }

    /// Збір закрито: мандарин переходить із тла на панель суцільною плашкою,
    /// і «Зібрано!» читається індиго — рівно навпаки до звичного стану.
    private func finished(side: CGFloat) -> some View {
        let labelSize = side * 0.030

        return HStack(alignment: .firstTextBaseline, spacing: side * 0.022) {
            Text(CampaignPosterFunding.finishedLabel)
                .campaignPosterFundingElement(.finished)
                .font(PosterFont.plexMonoRegular.size(labelSize))
                .tracking(labelSize * 0.16)
                .textCase(.uppercase)
                .foregroundStyle(Self.indigo)
                .padding(.horizontal, side * 0.02)
                .padding(.vertical, side * 0.009)
                .background(Self.tangerine)

            if let collected = funding.collected {
                Text(collected)
                    .campaignPosterFundingElement(.collected)
                    .font(PosterFont.oswaldBold.size(side * 0.066))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
        .modifier(PanelRule(side: side))
    }

    private struct PanelRule: ViewModifier {
        let side: CGFloat

        func body(content: Content) -> some View {
            content
                .padding(.top, side * 0.02)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(.white.opacity(0.4))
                        .frame(height: side * 0.002)
                }
        }
    }

    private static let tangerine = Color(red: 239/255, green: 115/255, blue: 38/255)
    private static let indigo = Color(red: 36/255, green: 33/255, blue: 94/255)
    private static let apricot = Color(red: 255/255, green: 179/255, blue: 122/255)
}

#Preview {
    PosterTemplatePreview { purpose, funding, photo in
        IndigoOrangeGradientTemplateView(purpose: purpose, funding: funding, viewProvider: photo)
    }
}
