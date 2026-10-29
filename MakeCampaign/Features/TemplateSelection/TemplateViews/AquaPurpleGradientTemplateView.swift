//
//  AquaPurpleGradientTemplateView.swift
//  MakeCampaign
//

import SwiftUI

/// `radialAquaPurple_squareTrailing` — an aqua bloom rising from the lower right
/// through violet into near-black, with the title set large in Playfair above a
/// square, drop-shadowed photo.
struct AquaPurpleGradientTemplateView: View {
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

            VStack(alignment: .leading, spacing: side * 0.03) {
                Text(purpose)
                    .campaignPosterElement(.campaignTitle)
                    .font(PosterFont.playfairExtraBold.size(side * 0.074))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.6)
                    .frame(maxWidth: .infinity, alignment: .leading)

                PosterPhoto(Rectangle(), photo: viewProvider)
                    .aspectRatio(1.0, contentMode: .fit)
                    .frame(maxWidth: side * 0.64, maxHeight: side * 0.64)
                    .shadow(
                        color: Color(red: 9/255, green: 4/255, blue: 26/255).opacity(0.45),
                        radius: side * 0.04,
                        x: 0,
                        y: side * 0.016
                    )
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: .infinity)

                caption(side: side)
            }
            .padding(side * 0.06)
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(background(side: side))
        }
    }

    private func background(side: CGFloat) -> some View {
        RadialGradient(
            stops: [
                .init(color: Self.aqua, location: 0),
                .init(color: Self.violet, location: 0.55),
                .init(color: Self.night, location: 1),
            ],
            center: UnitPoint(x: 0.7, y: 1.0),
            startRadius: 0,
            endRadius: side * 1.1
        )
    }

    @ViewBuilder
    private func caption(side: CGFloat) -> some View {
        if funding.isFinished {
            finished(side: side)
        } else if let goal = funding.goal {
            collecting(goal: goal, side: side)
        }
    }

    private func collecting(goal: String, side: CGFloat) -> some View {
        let labelSize = side * 0.031

        return VStack(alignment: .leading, spacing: side * 0.024) {
            // Ціль і підпис під нею — один блок: крок стосу тут заширокий,
            // щоб загальна ціль читалась як пояснення до суми.
            VStack(alignment: .leading, spacing: side * 0.008) {
                HStack(alignment: .firstTextBaseline, spacing: side * 0.024) {
                    Text(funding.goalLabel)
                        .font(PosterFont.plexMonoRegular.size(labelSize))
                        .tracking(labelSize * 0.18)
                        .textCase(.uppercase)
                        .foregroundStyle(Self.seafoam)

                    Text(goal)
                        .campaignPosterElement(.target)
                        .font(PosterFont.oswaldBold.size(side * 0.072))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }

                if let supportingGoal = funding.supportingGoal {
                    Text(supportingGoal)
                        .font(PosterFont.plexMonoRegular.size(labelSize * 0.86))
                        .foregroundStyle(Self.seafoam.opacity(0.8))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }

            if let fraction = funding.fraction {
                progress(fraction: fraction, side: side)
            }
        }
        .padding(.trailing, side * 0.26)
        .modifier(HairlineRule(side: side))
    }

    /// Смужка світиться аквамарином — тим самим, з якого починається сяйво
    /// у нижньому правому куті.
    private func progress(fraction: Double, side: CGFloat) -> some View {
        let labelSize = side * 0.028

        return VStack(alignment: .leading, spacing: side * 0.012) {
            PosterProgressBar(
                fraction: fraction,
                height: side * 0.012,
                track: .white.opacity(0.18),
                fill: Self.aqua
            )

            if let collected = funding.collected {
                Text("зібрано \(collected)")
                    .campaignPosterFundingElement(.collected)
                    .font(PosterFont.plexMonoRegular.size(labelSize))
                    .tracking(labelSize * 0.14)
                    .textCase(.uppercase)
                    .foregroundStyle(Self.seafoam.opacity(0.8))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
    }

    /// Збір закрито: сяйво з фону збирається в аквамаринову капсулу, і те, що
    /// було ціллю, стає підсумком.
    private func finished(side: CGFloat) -> some View {
        let labelSize = side * 0.031

        return HStack(alignment: .firstTextBaseline, spacing: side * 0.024) {
            Text(CampaignPosterFunding.finishedLabel)
                .campaignPosterFundingElement(.finished)
                .font(PosterFont.plexMonoRegular.size(labelSize))
                .tracking(labelSize * 0.18)
                .textCase(.uppercase)
                .foregroundStyle(Self.night)
                .padding(.horizontal, side * 0.022)
                .padding(.vertical, side * 0.01)
                .background(Self.aqua, in: Capsule())

            if let collected = funding.collected {
                Text(collected)
                    .campaignPosterFundingElement(.collected)
                    .font(PosterFont.oswaldBold.size(side * 0.072))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
        .padding(.trailing, side * 0.26)
        .modifier(HairlineRule(side: side))
    }

    private struct HairlineRule: ViewModifier {
        let side: CGFloat

        func body(content: Content) -> some View {
            content
                .padding(.top, side * 0.024)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(.white.opacity(0.45))
                        .frame(height: side * 0.002)
                }
        }
    }

    private static let aqua = Color(red: 46/255, green: 230/255, blue: 214/255)
    private static let violet = Color(red: 107/255, green: 58/255, blue: 214/255)
    private static let night = Color(red: 26/255, green: 11/255, blue: 63/255)
    private static let seafoam = Color(red: 185/255, green: 245/255, blue: 238/255)
}

#Preview {
    PosterTemplatePreview { purpose, funding, photo in
        AquaPurpleGradientTemplateView(purpose: purpose, funding: funding, viewProvider: photo)
    }
}
