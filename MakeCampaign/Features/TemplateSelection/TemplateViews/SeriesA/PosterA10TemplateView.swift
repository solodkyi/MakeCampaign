//
//  PosterA10TemplateView.swift
//  MakeCampaign
//

import SwiftUI

/// Набір A, `radialRedBlack_topToEdge` — the photo runs to the top edge and the
/// copy sits on a black foot that fades up into it, the title set in oblique
/// caps.
struct PosterA10TemplateView: View {
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
                PosterPhoto(Rectangle(), photo: viewProvider)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                caption(side: side)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(background(side: side))
        }
    }

    private func background(side: CGFloat) -> some View {
        RadialGradient(
            stops: [
                .init(color: Color(red: 200/255, green: 32/255, blue: 44/255), location: 0),
                .init(color: Color(red: 91/255, green: 10/255, blue: 18/255), location: 0.45),
                .init(color: Self.soot, location: 1),
            ],
            center: UnitPoint(x: 0.5, y: 0),
            startRadius: 0,
            endRadius: side * 0.9
        )
    }

    private func caption(side: CGFloat) -> some View {
        let purposeSize = side * 0.064

        return VStack(alignment: .leading, spacing: 0) {
            Text(purpose.uppercased())
                .campaignPosterElement(.campaignTitle)
                .font(PosterFont.oswaldBold.size(purposeSize))
                .italic()
                .lineSpacing(purposeSize * 0.02)
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
        .padding(.leading, side * 0.06)
        .padding(.trailing, side * 0.3)
        .padding(.top, side * 0.05)
        .padding(.bottom, side * 0.06)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            LinearGradient(
                stops: [
                    .init(color: Self.soot.opacity(0), location: 0),
                    .init(color: Self.soot, location: 0.22),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private func collecting(goal: String, side: CGFloat) -> some View {
        let labelSize = side * 0.032

        return VStack(alignment: .leading, spacing: side * 0.016) {
            VStack(alignment: .leading, spacing: side * 0.008) {
                HStack(alignment: .firstTextBaseline, spacing: side * 0.024) {
                    Text(funding.goalLabel)
                        .font(PosterFont.plexMonoRegular.size(labelSize))
                        .tracking(labelSize * 0.16)
                        .textCase(.uppercase)
                        .foregroundStyle(Self.flare)

                    Text(goal)
                        .campaignPosterElement(.target)
                        .font(PosterFont.oswaldBold.size(side * 0.086))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }

                if let supportingGoal = funding.supportingGoal {
                    Text(supportingGoal)
                        .font(PosterFont.plexMonoRegular.size(labelSize * 0.86))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }

            if let fraction = funding.fraction {
                progress(fraction: fraction, side: side)
            }
        }
        .padding(.top, side * 0.024)
    }

    /// Спалах — єдине, що світиться на сажі, тож смужка бере саме його.
    private func progress(fraction: Double, side: CGFloat) -> some View {
        let labelSize = side * 0.028

        return VStack(alignment: .leading, spacing: side * 0.01) {
            PosterProgressBar(
                fraction: fraction,
                shape: Rectangle(),
                height: side * 0.01,
                track: .white.opacity(0.16),
                fill: Self.flare
            )

            if let collected = funding.collected {
                Text("зібрано \(collected)")
                    .campaignPosterFundingElement(.collected)
                    .font(PosterFont.plexMonoRegular.size(labelSize))
                    .tracking(labelSize * 0.14)
                    .textCase(.uppercase)
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
    }

    /// Збір закрито: спалах густішає до суцільної плашки, і вигук читається
    /// сажею — так, наче його щойно випалили на плакаті.
    private func finished(side: CGFloat) -> some View {
        let labelSize = side * 0.032

        return HStack(alignment: .firstTextBaseline, spacing: side * 0.024) {
            Text(CampaignPosterFunding.finishedLabel)
                .campaignPosterFundingElement(.finished)
                .font(PosterFont.plexMonoRegular.size(labelSize))
                .tracking(labelSize * 0.16)
                .textCase(.uppercase)
                .foregroundStyle(Self.soot)
                .padding(.horizontal, side * 0.018)
                .padding(.vertical, side * 0.008)
                .background(Self.flare)

            if let collected = funding.collected {
                Text(collected)
                    .campaignPosterFundingElement(.collected)
                    .font(PosterFont.oswaldBold.size(side * 0.086))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
        .padding(.top, side * 0.024)
    }

    private static let soot = Color(red: 11/255, green: 7/255, blue: 8/255)
    private static let flare = Color(red: 255/255, green: 138/255, blue: 138/255)
}

#Preview {
    PosterTemplatePreview { purpose, funding, photo in
        PosterA10TemplateView(purpose: purpose, funding: funding, viewProvider: photo)
    }
}
