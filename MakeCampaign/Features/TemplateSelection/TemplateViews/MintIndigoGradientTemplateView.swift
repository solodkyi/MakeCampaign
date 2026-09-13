//
//  MintIndigoGradientTemplateView.swift
//  MakeCampaign
//

import SwiftUI

/// `radialMintIndigo_roundedTrailing` — a stack of rounded cards on a mint-to-
/// periwinkle wash: the title on indigo, the photo in the middle, the goal on
/// white.
///
/// Every card carries the same corner radius, which is what holds the three
/// separate blocks together as one stack.
struct MintIndigoGradientTemplateView: View {
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
            let radius = side * 0.04

            VStack(alignment: .leading, spacing: side * 0.03) {
                titleCard(side: side, radius: radius)

                PosterPhoto(RoundedRectangle(cornerRadius: radius, style: .continuous), photo: viewProvider)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                goalCard(side: side, radius: radius)
            }
            .padding(side * 0.05)
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(background)
        }
    }

    private var background: some View {
        LinearGradient(
            stops: [
                .init(color: Color(red: 216/255, green: 247/255, blue: 228/255), location: 0),
                .init(color: Color(red: 168/255, green: 233/255, blue: 207/255), location: 0.45),
                .init(color: Color(red: 111/255, green: 121/255, blue: 224/255), location: 1),
            ],
            startPoint: UnitPoint(x: 0.67, y: 0.03),
            endPoint: UnitPoint(x: 0.33, y: 0.97)
        )
    }

    private func titleCard(side: CGFloat, radius: CGFloat) -> some View {
        let kickerSize = side * 0.022
        let purposeSize = side * 0.05

        return VStack(alignment: .leading, spacing: side * 0.012) {
            Text("збір")
                .font(PosterFont.plexMonoRegular.size(kickerSize))
                .tracking(kickerSize * 0.28)
                .textCase(.uppercase)
                .foregroundStyle(Self.mint)

            Text(purpose)
                .campaignPosterElement(.campaignTitle)
                .font(PosterFont.oswaldMedium.size(purposeSize))
                .lineSpacing(purposeSize * 0.1)
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, side * 0.034)
        .padding(.vertical, side * 0.03)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Self.indigo, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
    }

    @ViewBuilder
    private func goalCard(side: CGFloat, radius: CGFloat) -> some View {
        if funding.isFinished {
            finishedCard(side: side, radius: radius)
        } else if let goal = funding.goal {
            collectingCard(goal: goal, side: side, radius: radius)
        }
    }

    private func collectingCard(
        goal: String,
        side: CGFloat,
        radius: CGFloat
    ) -> some View {
        let labelSize = side * 0.030

        return VStack(alignment: .leading, spacing: side * 0.018) {
            HStack(alignment: .firstTextBaseline, spacing: side * 0.02) {
                Text("ціль збору:")
                    .font(PosterFont.plexMonoRegular.size(labelSize))
                    .tracking(labelSize * 0.14)
                    .textCase(.uppercase)
                    .foregroundStyle(Self.periwinkleInk)

                Text(goal)
                    .campaignPosterElement(.target)
                    .font(PosterFont.oswaldBold.size(side * 0.064))
                    .foregroundStyle(Self.deepIndigo)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                Spacer(minLength: 0)
            }

            if let fraction = funding.fraction {
                progress(fraction: fraction, side: side)
            }
        }
        .modifier(Card(side: side, radius: radius))
    }

    /// Усередині білої картки смужка бере м'ятний — колір, яким світиться
    /// градієнт довкола неї.
    private func progress(fraction: Double, side: CGFloat) -> some View {
        let labelSize = side * 0.027

        return VStack(alignment: .leading, spacing: side * 0.01) {
            PosterProgressBar(
                fraction: fraction,
                height: side * 0.012,
                track: Self.periwinkleInk.opacity(0.16),
                fill: Self.indigo
            )

            if let collected = funding.collected {
                Text("зібрано \(collected)")
                    .campaignPosterFundingElement(.collected)
                    .font(PosterFont.plexMonoRegular.size(labelSize))
                    .tracking(labelSize * 0.14)
                    .textCase(.uppercase)
                    .foregroundStyle(Self.periwinkleInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
        .padding(.trailing, side * 0.22)
    }

    /// Збір закрито — картка міняється місцями з тлом: м'ята заливає її
    /// зсередини, а напис лягає глибоким індиго.
    private func finishedCard(side: CGFloat, radius: CGFloat) -> some View {
        let labelSize = side * 0.030

        return HStack(alignment: .firstTextBaseline, spacing: side * 0.02) {
            Text(CampaignPosterFunding.finishedLabel)
                .campaignPosterFundingElement(.finished)
                .font(PosterFont.plexMonoRegular.size(labelSize))
                .tracking(labelSize * 0.14)
                .textCase(.uppercase)
                .foregroundStyle(Self.deepIndigo)

            if let collected = funding.collected {
                Text(collected)
                    .campaignPosterFundingElement(.collected)
                    .font(PosterFont.oswaldBold.size(side * 0.064))
                    .foregroundStyle(Self.deepIndigo)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }

            Spacer(minLength: 0)
        }
        .modifier(Card(side: side, radius: radius, fill: Self.mint))
    }

    private struct Card: ViewModifier {
        let side: CGFloat
        let radius: CGFloat
        var fill: Color = .white

        func body(content: Content) -> some View {
            content
                .padding(.leading, side * 0.034)
                .padding(.trailing, side * 0.26)
                .padding(.vertical, side * 0.026)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    fill,
                    in: RoundedRectangle(cornerRadius: radius, style: .continuous)
                )
        }
    }

    private static let indigo = Color(red: 34/255, green: 39/255, blue: 107/255)
    private static let deepIndigo = Color(red: 23/255, green: 27/255, blue: 77/255)
    private static let mint = Color(red: 159/255, green: 240/255, blue: 205/255)
    private static let periwinkleInk = Color(red: 58/255, green: 64/255, blue: 144/255)
}

#Preview {
    PosterTemplatePreview { purpose, funding, photo in
        MintIndigoGradientTemplateView(purpose: purpose, funding: funding, viewProvider: photo)
    }
}
