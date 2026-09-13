//
//  GreenGradientTemplateView.swift
//  MakeCampaign
//

import SwiftUI

/// `linearGreen_topToBottomTrailing` — a voucher: forest-green header carrying
/// the title, a perforated tear line, then the goal and photo side by side on
/// pale card stock.
struct GreenGradientTemplateView: View {
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

            VStack(spacing: 0) {
                header(side: side)

                perforation(side: side)

                HStack(alignment: .center, spacing: side * 0.04) {
                    caption(side: side)

                    PosterPhoto(Rectangle(), photo: viewProvider)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .padding(side * 0.05)
                .frame(maxHeight: .infinity)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(Self.card)
        }
    }

    private func header(side: CGFloat) -> some View {
        let kickerSize = side * 0.023
        let purposeSize = side * 0.056

        return VStack(alignment: .leading, spacing: side * 0.02) {
            Text("збір")
                .font(PosterFont.plexMonoRegular.size(kickerSize))
                .tracking(kickerSize * 0.3)
                .textCase(.uppercase)
                .foregroundStyle(Self.lime)

            Text(purpose)
                .campaignPosterElement(.campaignTitle)
                .font(PosterFont.oswaldSemiBold.size(purposeSize))
                .lineSpacing(purposeSize * 0.06)
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, side * 0.06)
        .padding(.top, side * 0.06)
        .padding(.bottom, side * 0.05)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Self.forest)
    }

    /// The tear line: equal marks and gaps, so the header reads as a stub that
    /// could be pulled away from the card below it.
    private func perforation(side: CGFloat) -> some View {
        let dash = side * 0.03
        let count = Int((side / (dash * 2)).rounded(.up)) + 1

        return HStack(spacing: dash) {
            ForEach(0..<count, id: \.self) { _ in
                Rectangle()
                    .fill(Self.forest)
                    .frame(width: dash)
            }
        }
        .frame(height: dash)
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipped()
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
        let labelSize = side * 0.030
        let goalSize = side * 0.06

        return VStack(alignment: .leading, spacing: side * 0.008) {
            Spacer(minLength: 0)

            Text(funding.goalLabel)
                .font(PosterFont.plexMonoRegular.size(labelSize))
                .tracking(labelSize * 0.16)
                .textCase(.uppercase)
                .foregroundStyle(Self.moss)

            Text(goal)
                .campaignPosterElement(.target)
                .font(PosterFont.oswaldBold.size(goalSize))
                .lineSpacing(goalSize * 0.02)
                .foregroundStyle(Self.darkLeaf)
                .minimumScaleFactor(0.5)

            if let fraction = funding.fraction {
                progress(fraction: fraction, side: side)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    }

    /// Смужка на купоні — прямокутна, як усе на цьому бланку, лаймова на
    /// мохову доріжку.
    private func progress(fraction: Double, side: CGFloat) -> some View {
        let labelSize = side * 0.027

        return VStack(alignment: .leading, spacing: side * 0.01) {
            PosterProgressBar(
                fraction: fraction,
                shape: Rectangle(),
                height: side * 0.012,
                track: Self.moss.opacity(0.22),
                fill: Self.forest
            )

            if let collected = funding.collected {
                Text("зібрано \(collected)")
                    .campaignPosterFundingElement(.collected)
                    .font(PosterFont.plexMonoRegular.size(labelSize))
                    .tracking(labelSize * 0.14)
                    .textCase(.uppercase)
                    .foregroundStyle(Self.moss)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
        .padding(.top, side * 0.012)
    }

    /// Купон погашено: замість цілі — лаймовий штамп на лісовому, той самий
    /// колір, яким набрано «збір» у корінці.
    private func finished(side: CGFloat) -> some View {
        let labelSize = side * 0.030

        return VStack(alignment: .leading, spacing: side * 0.01) {
            Spacer(minLength: 0)

            Text(CampaignPosterFunding.finishedLabel)
                .campaignPosterFundingElement(.finished)
                .font(PosterFont.plexMonoRegular.size(labelSize))
                .tracking(labelSize * 0.16)
                .textCase(.uppercase)
                .foregroundStyle(Self.lime)
                .padding(.horizontal, side * 0.02)
                .padding(.vertical, side * 0.01)
                .background(Self.forest)

            if let collected = funding.collected {
                Text(collected)
                    .campaignPosterFundingElement(.collected)
                    .font(PosterFont.oswaldBold.size(side * 0.06))
                    .foregroundStyle(Self.darkLeaf)
                    .minimumScaleFactor(0.5)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    }

    private static let card = Color(red: 242/255, green: 245/255, blue: 233/255)
    private static let forest = Color(red: 20/255, green: 61/255, blue: 34/255)
    private static let lime = Color(red: 182/255, green: 224/255, blue: 106/255)
    private static let moss = Color(red: 61/255, green: 107/255, blue: 51/255)
    private static let darkLeaf = Color(red: 20/255, green: 41/255, blue: 26/255)
}

#Preview {
    PosterTemplatePreview { purpose, funding, photo in
        GreenGradientTemplateView(purpose: purpose, funding: funding, viewProvider: photo)
    }
}
