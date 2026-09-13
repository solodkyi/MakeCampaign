//
//  PosterA01TemplateView.swift
//  MakeCampaign
//

import SwiftUI

/// Набір A, `blueLinear_center` — pastel banners notched like a pennant, top and
/// bottom, with a framed square photo between them on a deep blue wash.
struct PosterA01TemplateView: View {
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

                photo(side: side)
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: .infinity)
                    .padding(.vertical, side * 0.04)

                caption(side: side)
            }
            .padding(side * 0.05)
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(background)
        }
    }

    private var background: some View {
        LinearGradient(
            stops: [
                .init(color: Color(red: 16/255, green: 24/255, blue: 74/255), location: 0),
                .init(color: Color(red: 36/255, green: 53/255, blue: 127/255), location: 0.46),
                .init(color: Color(red: 143/255, green: 196/255, blue: 232/255), location: 1),
            ],
            startPoint: UnitPoint(x: 0.25, y: 0.07),
            endPoint: UnitPoint(x: 0.75, y: 0.93)
        )
    }

    private func header(side: CGFloat) -> some View {
        let kickerSize = side * 0.024
        let purposeSize = side * 0.054

        return VStack(alignment: .leading, spacing: side * 0.006) {
            Text("збір")
                .font(PosterFont.plexMonoRegular.size(kickerSize))
                .tracking(kickerSize * 0.16)
                .textCase(.uppercase)
                .foregroundStyle(Self.plum)

            Text(purpose)
                .campaignPosterElement(.campaignTitle)
                .font(PosterFont.oswaldSemiBold.size(purposeSize))
                .lineSpacing(purposeSize * 0.05)
                .foregroundStyle(Self.ink)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.6)
        }
        .padding(.horizontal, side * 0.03)
        .padding(.vertical, side * 0.022)
        .frame(maxWidth: side * 0.74, alignment: .leading)
        .background(Self.pastel, in: PosterNotchedBanner(notch: side * 0.026))
    }

    private func photo(side: CGFloat) -> some View {
        PosterPhoto(Rectangle(), photo: viewProvider)
            .padding(side * 0.016)
            .background(Self.pastel)
            .aspectRatio(1.0, contentMode: .fit)
            .frame(maxWidth: side * 0.62, maxHeight: side * 0.62)
            .shadow(
                color: Color(red: 6/255, green: 10/255, blue: 40/255).opacity(0.4),
                radius: side * 0.05,
                x: 0,
                y: side * 0.02
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
        let labelSize = side * 0.032

        return VStack(alignment: .leading, spacing: side * 0.004) {
            Text("ціль збору:")
                .font(PosterFont.plexMonoRegular.size(labelSize))
                .tracking(labelSize * 0.16)
                .textCase(.uppercase)
                .foregroundStyle(Self.plum)

            Text(goal)
                .campaignPosterElement(.target)
                .font(PosterFont.oswaldBold.size(side * 0.07))
                .foregroundStyle(Self.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            if let fraction = funding.fraction {
                progress(fraction: fraction, side: side)
            }
        }
        .modifier(Banner(side: side))
    }

    /// Смужка живе всередині вимпела, тож бере його ж сливовий — інакше
    /// вона розірвала б пастельну плашку третім кольором.
    private func progress(fraction: Double, side: CGFloat) -> some View {
        let labelSize = side * 0.028

        return VStack(alignment: .leading, spacing: side * 0.008) {
            PosterProgressBar(
                fraction: fraction,
                shape: Rectangle(),
                height: side * 0.01,
                track: Self.plum.opacity(0.2),
                fill: Self.plum
            )

            if let collected = funding.collected {
                Text("зібрано \(collected)")
                    .campaignPosterFundingElement(.collected)
                    .font(PosterFont.plexMonoRegular.size(labelSize))
                    .tracking(labelSize * 0.14)
                    .textCase(.uppercase)
                    .foregroundStyle(Self.plum)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
        .padding(.top, side * 0.008)
        .padding(.trailing, side * 0.03)
    }

    /// Збір закрито: вимпел темніє до сливового, а напис читається пастеллю —
    /// та сама стрічка, тільки вивернута.
    private func finished(side: CGFloat) -> some View {
        let labelSize = side * 0.032

        return VStack(alignment: .leading, spacing: side * 0.004) {
            Text(CampaignPosterFunding.finishedLabel)
                .campaignPosterFundingElement(.finished)
                .font(PosterFont.plexMonoRegular.size(labelSize))
                .tracking(labelSize * 0.16)
                .textCase(.uppercase)
                .foregroundStyle(Self.pastel)

            if let collected = funding.collected {
                Text(collected)
                    .campaignPosterFundingElement(.collected)
                    .font(PosterFont.oswaldBold.size(side * 0.07))
                    .foregroundStyle(Self.pastel)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
        .modifier(Banner(side: side, fill: Self.plum))
    }

    private struct Banner: ViewModifier {
        let side: CGFloat
        var fill: Color = Color(red: 243/255, green: 220/255, blue: 240/255)

        func body(content: Content) -> some View {
            content
                .padding(.horizontal, side * 0.03)
                .padding(.vertical, side * 0.022)
                .background(fill, in: PosterNotchedBanner(notch: side * 0.026))
                .padding(.trailing, side * 0.26)
        }
    }

    private static let pastel = Color(red: 243/255, green: 220/255, blue: 240/255)
    private static let plum = Color(red: 109/255, green: 47/255, blue: 102/255)
    private static let ink = Color(red: 35/255, green: 16/255, blue: 63/255)
}

#Preview {
    PosterTemplatePreview { purpose, funding, photo in
        PosterA01TemplateView(purpose: purpose, funding: funding, viewProvider: photo)
    }
}
