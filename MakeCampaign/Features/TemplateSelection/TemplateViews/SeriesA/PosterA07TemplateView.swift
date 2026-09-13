//
//  PosterA07TemplateView.swift
//  MakeCampaign
//

import SwiftUI

/// Набір A, `linearGreen_topToBottomTrailing` — deep green rising to lime, the
/// copy down the left and the photo filling the right half to the edges, with
/// the goal on a pale card.
struct PosterA07TemplateView: View {
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

            HStack(spacing: 0) {
                copy(side: side)
                    .frame(width: geometry.size.width * 0.46, alignment: .leading)

                PosterPhoto(Rectangle(), photo: viewProvider)
                    .frame(width: geometry.size.width * 0.54)
                    .frame(maxHeight: .infinity)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(background)
        }
    }

    private var background: some View {
        LinearGradient(
            stops: [
                .init(color: Color(red: 15/255, green: 59/255, blue: 40/255), location: 0),
                .init(color: Color(red: 30/255, green: 107/255, blue: 64/255), location: 0.6),
                .init(color: Color(red: 168/255, green: 217/255, blue: 75/255), location: 1),
            ],
            startPoint: UnitPoint(x: 0.33, y: 0.03),
            endPoint: UnitPoint(x: 0.67, y: 0.97)
        )
    }

    private func copy(side: CGFloat) -> some View {
        let kickerSize = side * 0.024
        let purposeSize = side * 0.054

        return VStack(alignment: .leading, spacing: 0) {
            Text("збір")
                .font(PosterFont.plexMonoRegular.size(kickerSize))
                .tracking(kickerSize * 0.28)
                .textCase(.uppercase)
                .foregroundStyle(Self.lime)

            Text(purpose)
                .campaignPosterElement(.campaignTitle)
                .font(PosterFont.oswaldSemiBold.size(purposeSize))
                .lineSpacing(purposeSize * 0.08)
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, side * 0.016)

            Spacer(minLength: side * 0.04)

            caption(side: side)
        }
        .padding(.leading, side * 0.06)
        .padding(.trailing, side * 0.04)
        .padding(.vertical, side * 0.06)
        .frame(maxHeight: .infinity, alignment: .topLeading)
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

        return VStack(alignment: .leading, spacing: side * 0.006) {
            Text(funding.goalLabel)
                .font(PosterFont.plexMonoRegular.size(labelSize))
                .tracking(labelSize * 0.16)
                .textCase(.uppercase)
                .foregroundStyle(Self.moss)

            Text(goal)
                .campaignPosterElement(.target)
                .font(PosterFont.oswaldBold.size(side * 0.074))
                .lineSpacing(side * 0.074 * 0.02)
                .foregroundStyle(Self.darkLeaf)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            // Картка світла, тож підпис бере її мохове чорнило.
            if let supportingGoal = funding.supportingGoal {
                Text(supportingGoal)
                    .font(PosterFont.plexMonoRegular.size(labelSize * 0.86))
                    .foregroundStyle(Self.moss)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.top, side * 0.006)
            }

            if let fraction = funding.fraction {
                progress(fraction: fraction, side: side)
            }
        }
        .modifier(Card(side: side))
    }

    /// Усередині світлої картки смужка бере лайм із тла — так поступ
    /// прив'язує картку до плаката, на якому вона лежить.
    private func progress(fraction: Double, side: CGFloat) -> some View {
        let labelSize = side * 0.027

        return VStack(alignment: .leading, spacing: side * 0.01) {
            PosterProgressBar(
                fraction: fraction,
                shape: Rectangle(),
                height: side * 0.012,
                track: Self.moss.opacity(0.18),
                fill: Self.moss
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
        .padding(.top, side * 0.008)
    }

    /// Збір закрито: картка темніє до мохового, а напис читається лаймом —
    /// той самий колір, що тримає весь плакат.
    private func finished(side: CGFloat) -> some View {
        let labelSize = side * 0.030

        return VStack(alignment: .leading, spacing: side * 0.006) {
            Text(CampaignPosterFunding.finishedLabel)
                .campaignPosterFundingElement(.finished)
                .font(PosterFont.plexMonoRegular.size(labelSize))
                .tracking(labelSize * 0.16)
                .textCase(.uppercase)
                .foregroundStyle(Self.lime)

            if let collected = funding.collected {
                Text(collected)
                    .campaignPosterFundingElement(.collected)
                    .font(PosterFont.oswaldBold.size(side * 0.074))
                    .foregroundStyle(Self.card)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
        .modifier(Card(side: side, fill: Self.darkLeaf))
    }

    private struct Card: ViewModifier {
        let side: CGFloat
        var fill: Color = Color(red: 244/255, green: 247/255, blue: 236/255)

        func body(content: Content) -> some View {
            content
                .padding(.horizontal, side * 0.028)
                .padding(.vertical, side * 0.026)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(fill)
        }
    }

    private static let lime = Color(red: 205/255, green: 240/255, blue: 122/255)
    private static let card = Color(red: 244/255, green: 247/255, blue: 236/255)
    private static let moss = Color(red: 44/255, green: 91/255, blue: 52/255)
    private static let darkLeaf = Color(red: 17/255, green: 41/255, blue: 26/255)
}

#Preview {
    PosterTemplatePreview { purpose, funding, photo in
        PosterA07TemplateView(purpose: purpose, funding: funding, viewProvider: photo)
    }
}
