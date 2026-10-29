//
//  EmeraldBlackGradientTemplateView.swift
//  MakeCampaign
//

import SwiftUI

/// `linearEmeraldBlack_hexagonTrailing` — an instrument readout: near-black
/// ground, a large hexagonal reticle centred behind the content, and the photo
/// cut to a matching hexagon.
struct EmeraldBlackGradientTemplateView: View {
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
                header(side: side)

                PosterPhoto(PosterHexagon(), photo: viewProvider)
                    .aspectRatio(0.92, contentMode: .fit)
                    .frame(maxWidth: side * 0.52, maxHeight: side * 0.52)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .frame(maxHeight: .infinity)
                    .padding(.vertical, side * 0.035)

                caption(side: side)
            }
            .padding(side * 0.06)
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background {
                Self.pitch.overlay { reticle(side: side) }
            }
        }
    }

    private func reticle(side: CGFloat) -> some View {
        PosterHexagon()
            .fill(
                RadialGradient(
                    colors: [Self.neon.opacity(0.14), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: side * 0.46 * 0.65
                )
            )
            .overlay {
                PosterHexagon()
                    .stroke(Self.neon.opacity(0.35), lineWidth: side * 0.0025)
            }
            .frame(width: side * 0.92, height: side * 0.92)
    }

    private func header(side: CGFloat) -> some View {
        let kickerSize = side * 0.022
        let purposeSize = side * 0.052

        return VStack(alignment: .leading, spacing: side * 0.014) {
            Text("збір")
                .font(PosterFont.plexMonoRegular.size(kickerSize))
                .tracking(kickerSize * 0.34)
                .textCase(.uppercase)
                .foregroundStyle(Self.neon)

            Text(purpose)
                .campaignPosterElement(.campaignTitle)
                .font(PosterFont.oswaldMedium.size(purposeSize))
                .lineSpacing(purposeSize * 0.1)
                .foregroundStyle(Self.frost)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: side * 0.66, alignment: .leading)
        }
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

        return VStack(alignment: .leading, spacing: side * 0.008) {
            Text(funding.goalLabel)
                .font(PosterFont.plexMonoRegular.size(labelSize))
                .tracking(labelSize * 0.18)
                .textCase(.uppercase)
                .foregroundStyle(Self.neon)

            Text(goal)
                .campaignPosterElement(.target)
                .font(PosterFont.oswaldBold.size(side * 0.08))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            if let supportingGoal = funding.supportingGoal {
                Text(supportingGoal)
                    .font(PosterFont.plexMonoRegular.size(labelSize * 0.86))
                    .foregroundStyle(Self.frost.opacity(0.66))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.top, side * 0.004)
            }

            if let fraction = funding.fraction {
                progress(fraction: fraction, side: side)
            }
        }
        .padding(.trailing, side * 0.26)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Смужка світиться тим самим неоном, що обводить шестикутник, — на смолі
    /// вона читається як індикатор, а не як прикраса.
    private func progress(fraction: Double, side: CGFloat) -> some View {
        let labelSize = side * 0.027

        return VStack(alignment: .leading, spacing: side * 0.012) {
            PosterProgressBar(
                fraction: fraction,
                shape: Rectangle(),
                height: side * 0.01,
                track: Self.neon.opacity(0.16),
                fill: Self.neon
            )

            if let collected = funding.collected {
                Text("зібрано \(collected)")
                    .campaignPosterFundingElement(.collected)
                    .font(PosterFont.plexMonoRegular.size(labelSize))
                    .tracking(labelSize * 0.16)
                    .textCase(.uppercase)
                    .foregroundStyle(Self.frost.opacity(0.66))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
        .padding(.top, side * 0.016)
    }

    /// Збір закрито: неон нарешті заливає плашку суцільним, і напис читається
    /// смолою по зеленому — інверсія того, чим шаблон жив досі.
    private func finished(side: CGFloat) -> some View {
        let labelSize = side * 0.031

        return VStack(alignment: .leading, spacing: side * 0.012) {
            Text(CampaignPosterFunding.finishedLabel)
                .campaignPosterFundingElement(.finished)
                .font(PosterFont.plexMonoRegular.size(labelSize))
                .tracking(labelSize * 0.18)
                .textCase(.uppercase)
                .foregroundStyle(Self.pitch)
                .padding(.horizontal, side * 0.022)
                .padding(.vertical, side * 0.01)
                .background(Self.neon)

            if let collected = funding.collected {
                Text(collected)
                    .campaignPosterFundingElement(.collected)
                    .font(PosterFont.oswaldBold.size(side * 0.08))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
        .padding(.trailing, side * 0.26)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private static let pitch = Color(red: 4/255, green: 18/255, blue: 12/255)
    private static let neon = Color(red: 29/255, green: 233/255, blue: 158/255)
    private static let frost = Color(red: 234/255, green: 255/255, blue: 245/255)
}

#Preview {
    PosterTemplatePreview { purpose, funding, photo in
        EmeraldBlackGradientTemplateView(purpose: purpose, funding: funding, viewProvider: photo)
    }
}
