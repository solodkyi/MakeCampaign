//
//  PinkGradientTemplateView.swift
//  MakeCampaign
//

import SwiftUI

/// `pinkAngular_topCenter` — a polaroid tilted on a swept pink ground, with the
/// title on a black slug and the goal in a yellow capsule.
///
/// The card, the slug and the capsule are each rotated by a different small
/// amount; matching them would read as a mistake rather than a collage.
struct PinkGradientTemplateView: View {
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

            VStack(alignment: .leading, spacing: 0) {
                polaroid(side: side)
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: .infinity)
                    .padding(.bottom, side * 0.04)

                caption(side: side)
            }
            .padding(side * 0.06)
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(background)
        }
    }

    private var background: some View {
        AngularGradient(
            stops: [
                .init(color: Self.hot, location: 0),
                .init(color: Self.blush, location: 120.0 / 360.0),
                .init(color: Self.wine, location: 300.0 / 360.0),
                .init(color: Self.hot, location: 1),
            ],
            center: UnitPoint(x: 0.7, y: 0.2),
            angle: .degrees(40)
        )
    }

    private func polaroid(side: CGFloat) -> some View {
        PosterPhoto(Rectangle(), photo: viewProvider)
            .padding(.horizontal, side * 0.02)
            .padding(.top, side * 0.02)
            .padding(.bottom, side * 0.06)
            .background(.white)
            .aspectRatio(1.0, contentMode: .fit)
                    .frame(maxWidth: side * 0.66, maxHeight: side * 0.66)
            .rotationEffect(.degrees(-4))
            .shadow(
                color: Color(red: 60/255, green: 5/255, blue: 30/255).opacity(0.35),
                radius: side * 0.05,
                x: 0,
                y: side * 0.02
            )
    }

    private func caption(side: CGFloat) -> some View {
        let purposeSize = side * 0.05

        return VStack(alignment: .leading, spacing: side * 0.026) {
            Text(purpose.uppercased())
                .campaignPosterElement(.campaignTitle)
                .font(PosterFont.oswaldSemiBold.size(purposeSize))
                .lineSpacing(purposeSize * 0.1)
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.6)
                .padding(.horizontal, side * 0.03)
                .padding(.vertical, side * 0.02)
                .background(Self.tar)
                .frame(maxWidth: side * 0.84, alignment: .leading)
                .rotationEffect(.degrees(-1.5))

            if funding.isFinished {
                finished(side: side)
            } else if let goal = funding.goal {
                collecting(goal: goal, side: side)
            }
        }
    }

    private func collecting(goal: String, side: CGFloat) -> some View {
        let labelSize = side * 0.030

        return VStack(alignment: .leading, spacing: side * 0.016) {
            HStack(alignment: .firstTextBaseline, spacing: side * 0.022) {
                Text(funding.goalLabel)
                    .font(PosterFont.plexMonoRegular.size(labelSize))
                    .tracking(labelSize * 0.14)
                    .textCase(.uppercase)
                    .foregroundStyle(Self.amberInk)

                Text(goal)
                    .campaignPosterElement(.target)
                    .font(PosterFont.oswaldBold.size(side * 0.064))
                    .foregroundStyle(Self.tar)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .padding(.horizontal, side * 0.03)
            .padding(.vertical, side * 0.02)
            .background(Self.lemon, in: Capsule())

            if let fraction = funding.fraction {
                progress(fraction: fraction, side: side)
            }
        }
    }

    /// Смужка теж капсула — на цьому плакаті все округле, тож поступ
    /// повторює форму лимонної плашки над ним.
    private func progress(fraction: Double, side: CGFloat) -> some View {
        let labelSize = side * 0.027

        return VStack(alignment: .leading, spacing: side * 0.01) {
            PosterProgressBar(
                fraction: fraction,
                height: side * 0.016,
                track: Self.wine.opacity(0.45),
                fill: Self.lemon
            )

            if let collected = funding.collected {
                Text("зібрано \(collected)")
                    .campaignPosterFundingElement(.collected)
                    .font(PosterFont.plexMonoRegular.size(labelSize))
                    .tracking(labelSize * 0.14)
                    .textCase(.uppercase)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
        .padding(.horizontal, side * 0.006)
        .frame(maxWidth: side * 0.7, alignment: .leading)
    }

    /// Збір закрито: лимонна капсула лишається, але тепер вона несе не ціль,
    /// а вигук — і нахилена так само, як чорний слуг із назвою.
    private func finished(side: CGFloat) -> some View {
        let labelSize = side * 0.04

        return VStack(alignment: .leading, spacing: side * 0.016) {
            Text(CampaignPosterFunding.finishedLabel.uppercased())
                .campaignPosterFundingElement(.finished)
                .font(PosterFont.oswaldBold.size(labelSize))
                .tracking(labelSize * 0.1)
                .foregroundStyle(Self.tar)
                .padding(.horizontal, side * 0.03)
                .padding(.vertical, side * 0.02)
                .background(Self.lemon, in: Capsule())
                .rotationEffect(.degrees(-1.5))

            if let collected = funding.collected {
                Text(collected)
                    .campaignPosterFundingElement(.collected)
                    .font(PosterFont.oswaldBold.size(side * 0.064))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal, side * 0.006)
            }
        }
    }

    private static let hot = Color(red: 255/255, green: 79/255, blue: 147/255)
    private static let blush = Color(red: 255/255, green: 138/255, blue: 184/255)
    private static let wine = Color(red: 109/255, green: 11/255, blue: 56/255)
    private static let tar = Color(red: 23/255, green: 2/255, blue: 12/255)
    private static let lemon = Color(red: 255/255, green: 225/255, blue: 79/255)
    private static let amberInk = Color(red: 109/255, green: 59/255, blue: 0/255)
}

#Preview {
    PosterTemplatePreview { purpose, funding, photo in
        PinkGradientTemplateView(purpose: purpose, funding: funding, viewProvider: photo)
    }
}
