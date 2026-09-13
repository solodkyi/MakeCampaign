//
//  PosterA04TemplateView.swift
//  MakeCampaign
//

import SwiftUI

/// Набір A, `goldBlackLinear_hexagonTrailing` — gold on near-black, lit by a
/// soft glow off the top-right corner, with the photo set in a solid gold
/// hexagon.
struct PosterA04TemplateView: View {
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
                    .padding(side * 0.008)
                    .background { PosterHexagon().fill(Self.gold) }
                    .aspectRatio(1.0, contentMode: .fit)
                    .frame(maxWidth: side * 0.58, maxHeight: side * 0.58)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .frame(maxHeight: .infinity)
                    .padding(.vertical, side * 0.04)

                caption(side: side)
            }
            .padding(side * 0.06)
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background {
                background.overlay(alignment: .topTrailing) {
                    RadialGradient(
                        colors: [Self.gold.opacity(0.42), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: side * 0.3
                    )
                    .frame(width: side * 0.6, height: side * 0.6)
                    .offset(x: side * 0.1, y: -side * 0.08)
                }
            }
        }
    }

    private var background: some View {
        LinearGradient(
            stops: [
                .init(color: Color(red: 26/255, green: 22/255, blue: 8/255), location: 0),
                .init(color: Color(red: 20/255, green: 18/255, blue: 12/255), location: 0.52),
                .init(color: Color(red: 10/255, green: 10/255, blue: 8/255), location: 1),
            ],
            startPoint: UnitPoint(x: 0.79, y: 0.09),
            endPoint: UnitPoint(x: 0.21, y: 0.91)
        )
    }

    private func header(side: CGFloat) -> some View {
        let kickerSize = side * 0.023
        let purposeSize = side * 0.064

        return VStack(alignment: .leading, spacing: side * 0.016) {
            Text("збір")
                .font(PosterFont.plexMonoRegular.size(kickerSize))
                .tracking(kickerSize * 0.32)
                .textCase(.uppercase)
                .foregroundStyle(Self.gold)

            Text(purpose.uppercased())
                .campaignPosterElement(.campaignTitle)
                .font(PosterFont.oswaldSemiBold.size(purposeSize))
                .lineSpacing(purposeSize * 0.06)
                .foregroundStyle(Self.parchment)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: side * 0.6, alignment: .leading)
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
        let labelSize = side * 0.035

        return VStack(spacing: side * 0.018) {
            HStack(alignment: .firstTextBaseline, spacing: side * 0.02) {
                Text("ціль збору:")
                    .font(PosterFont.plexMonoRegular.size(labelSize))
                    .tracking(labelSize * 0.14)
                    .textCase(.uppercase)
                    .foregroundStyle(Self.gold)

                Spacer(minLength: 0)

                Text(goal)
                    .campaignPosterElement(.target)
                    .font(PosterFont.oswaldBold.size(side * 0.09))
                    .foregroundStyle(Self.parchment)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }

            if let fraction = funding.fraction {
                progress(fraction: fraction, side: side)
            }
        }
        .modifier(GoldRule(side: side))
    }

    /// Смужка — та сама золота лінія, що ділить плакат, тільки нижча й
    /// заповнена лише до досягнутого.
    private func progress(fraction: Double, side: CGFloat) -> some View {
        let labelSize = side * 0.030

        return HStack(spacing: side * 0.024) {
            PosterProgressBar(
                fraction: fraction,
                shape: Rectangle(),
                height: side * 0.008,
                track: Self.gold.opacity(0.24),
                fill: Self.gold
            )

            if let collected = funding.collected {
                Text(collected)
                    .campaignPosterFundingElement(.collected)
                    .font(PosterFont.plexMonoRegular.size(labelSize))
                    .foregroundStyle(Self.gold)
                    .lineLimit(1)
                    .fixedSize()
            }
        }
    }

    /// Збір закрито: золото зі смужки збирається в суцільну плашку, і вигук
    /// читається темним по золотому.
    private func finished(side: CGFloat) -> some View {
        let labelSize = side * 0.035

        return HStack(alignment: .firstTextBaseline, spacing: side * 0.02) {
            Text(CampaignPosterFunding.finishedLabel)
                .campaignPosterFundingElement(.finished)
                .font(PosterFont.plexMonoRegular.size(labelSize))
                .tracking(labelSize * 0.14)
                .textCase(.uppercase)
                .foregroundStyle(Self.pitch)
                .padding(.horizontal, side * 0.02)
                .padding(.vertical, side * 0.008)
                .background(Self.gold)

            Spacer(minLength: 0)

            if let collected = funding.collected {
                Text(collected)
                    .campaignPosterFundingElement(.collected)
                    .font(PosterFont.oswaldBold.size(side * 0.09))
                    .foregroundStyle(Self.parchment)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
        .modifier(GoldRule(side: side))
    }

    private struct GoldRule: ViewModifier {
        let side: CGFloat

        func body(content: Content) -> some View {
            content
                .padding(.top, side * 0.024)
                .padding(.trailing, side * 0.26)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Self.gold)
                        .frame(height: side * 0.004)
                }
        }

        private static let gold = Color(red: 226/255, green: 178/255, blue: 61/255)
    }

    private static let pitch = Color(red: 22/255, green: 18/255, blue: 10/255)

    private static let gold = Color(red: 226/255, green: 178/255, blue: 61/255)
    private static let parchment = Color(red: 246/255, green: 241/255, blue: 228/255)
}

#Preview {
    PosterTemplatePreview { purpose, funding, photo in
        PosterA04TemplateView(purpose: purpose, funding: funding, viewProvider: photo)
    }
}
