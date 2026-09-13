//
//  GoldBlackGradientTemplateView.swift
//  MakeCampaign
//

import SwiftUI

/// `goldBlackLinear_hexagonTrailing` — light gold washing across bone paper,
/// set in Playfair, with the photo cut to a hexagon over a struck-gold backing.
///
/// The backing sits slightly proud of the photo on every edge, which is what
/// reads as a bevelled setting rather than a border.
struct GoldBlackGradientTemplateView: View {
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
                kicker(side: side)

                photo(side: side)
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: .infinity)
                    .padding(.vertical, side * 0.03)

                caption(side: side)
            }
            .padding(side * 0.06)
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(background)
        }
    }

    private var background: some View {
        LinearGradient(
            stops: [
                .init(color: Color(red: 247/255, green: 242/255, blue: 226/255), location: 0),
                .init(color: Color(red: 236/255, green: 223/255, blue: 184/255), location: 0.6),
                .init(color: Color(red: 203/255, green: 171/255, blue: 99/255), location: 1),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func kicker(side: CGFloat) -> some View {
        let size = side * 0.022

        return Text("збір")
            .font(PosterFont.plexMonoRegular.size(size))
            .tracking(size * 0.36)
            .textCase(.uppercase)
            .foregroundStyle(Self.bronze)
    }

    private func photo(side: CGFloat) -> some View {
        PosterPhoto(PosterHexagon(), photo: viewProvider)
            .padding(side * 0.014)
            .background {
                PosterHexagon().fill(Self.struckGold)
            }
            .aspectRatio(1.0, contentMode: .fit)
                    .frame(maxWidth: side * 0.56, maxHeight: side * 0.56)
    }

    private func caption(side: CGFloat) -> some View {
        let purposeSize = side * 0.066

        return VStack(alignment: .leading, spacing: side * 0.024) {
            Text(purpose)
                .campaignPosterElement(.campaignTitle)
                .font(PosterFont.playfairBold.size(purposeSize))
                .lineSpacing(purposeSize * 0.02)
                .foregroundStyle(Self.ink)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity, alignment: .leading)

            if funding.isFinished {
                finished(side: side)
            } else if let goal = funding.goal {
                collecting(goal: goal, side: side)
            }
        }
    }

    private func collecting(goal: String, side: CGFloat) -> some View {
        let labelSize = side * 0.031

        return VStack(alignment: .leading, spacing: side * 0.022) {
            HStack(alignment: .firstTextBaseline, spacing: side * 0.024) {
                Text(funding.goalLabel)
                    .font(PosterFont.plexMonoRegular.size(labelSize))
                    .tracking(labelSize * 0.16)
                    .textCase(.uppercase)
                    .foregroundStyle(Self.deepBronze)

                Text(goal)
                    .campaignPosterElement(.target)
                    .font(PosterFont.playfairBoldItalic.size(side * 0.076))
                    .foregroundStyle(Self.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }

            if let fraction = funding.fraction {
                progress(fraction: fraction, side: side)
            }
        }
        .padding(.trailing, side * 0.26)
        .modifier(GoldRule(side: side))
    }

    /// Тонка смужка кутого золота на блідому тлі — та сама лінія, що ділить
    /// назву й суму, тільки заповнена до досягнутої частки.
    private func progress(fraction: Double, side: CGFloat) -> some View {
        let labelSize = side * 0.028

        return VStack(alignment: .leading, spacing: side * 0.012) {
            PosterProgressBar(
                fraction: fraction,
                shape: Rectangle(),
                height: side * 0.01,
                track: Self.struckGold.opacity(0.22),
                fill: Self.struckGold
            )

            if let collected = funding.collected {
                Text("зібрано \(collected)")
                    .campaignPosterFundingElement(.collected)
                    .font(PosterFont.plexMonoRegular.size(labelSize))
                    .tracking(labelSize * 0.14)
                    .textCase(.uppercase)
                    .foregroundStyle(Self.bronze)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
    }

    /// Збір закрито — і закрито він курсивом Playfair, як підпис під
    /// готовою справою: «Зібрано!» набране тим самим накресленням, що й сума.
    private func finished(side: CGFloat) -> some View {
        let labelSize = side * 0.031

        return VStack(alignment: .leading, spacing: side * 0.01) {
            Text(CampaignPosterFunding.finishedLabel)
                .campaignPosterFundingElement(.finished)
                .font(PosterFont.playfairBoldItalic.size(side * 0.076))
                .foregroundStyle(Self.struckGold)

            if let collected = funding.collected {
                HStack(alignment: .firstTextBaseline, spacing: side * 0.024) {
                    Text("разом:")
                        .font(PosterFont.plexMonoRegular.size(labelSize))
                        .tracking(labelSize * 0.16)
                        .textCase(.uppercase)
                        .foregroundStyle(Self.deepBronze)

                    Text(collected)
                        .campaignPosterFundingElement(.collected)
                        .font(PosterFont.playfairBold.size(side * 0.068))
                        .foregroundStyle(Self.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
        }
        .padding(.trailing, side * 0.26)
        .modifier(GoldRule(side: side))
    }

    private struct GoldRule: ViewModifier {
        let side: CGFloat

        func body(content: Content) -> some View {
            content
                .padding(.top, side * 0.022)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Self.rule)
                        .frame(height: side * 0.002)
                }
        }

        private static let rule = Color(red: 140/255, green: 106/255, blue: 31/255)
    }

    private static let ink = Color(red: 44/255, green: 33/255, blue: 10/255)
    private static let bronze = Color(red: 122/255, green: 92/255, blue: 25/255)
    private static let deepBronze = Color(red: 106/255, green: 79/255, blue: 20/255)
    private static let struckGold = Color(red: 140/255, green: 106/255, blue: 31/255)
}

#Preview {
    PosterTemplatePreview { purpose, funding, photo in
        GoldBlackGradientTemplateView(purpose: purpose, funding: funding, viewProvider: photo)
    }
}
