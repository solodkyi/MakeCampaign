//
//  PosterA11TemplateView.swift
//  MakeCampaign
//

import SwiftUI

/// Набір A, `linearIndigoOrange_trailing` — indigo bleeding into orange, a
/// marker dot beside the title, and the photo held off the trailing edge behind
/// a thick orange rule.
struct PosterA11TemplateView: View {
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

            VStack(alignment: .leading, spacing: side * 0.035) {
                HStack(alignment: .top, spacing: side * 0.03) {
                    Text(purpose.uppercased())
                        .campaignPosterElement(.campaignTitle)
                        .font(PosterFont.oswaldSemiBold.size(side * 0.056))
                        .lineSpacing(side * 0.056 * 0.06)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                        .minimumScaleFactor(0.6)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Circle()
                        .fill(Self.amber)
                        .frame(width: side * 0.08, height: side * 0.08)
                }

                PosterPhoto(Rectangle(), photo: viewProvider)
                    .overlay(alignment: .leading) {
                        Rectangle()
                            .fill(Self.amber)
                            .frame(width: side * 0.012)
                    }
                    .frame(width: side * 0.72)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .frame(maxHeight: .infinity)

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
                .init(color: Color(red: 29/255, green: 31/255, blue: 92/255), location: 0),
                .init(color: Color(red: 43/255, green: 47/255, blue: 126/255), location: 0.55),
                .init(color: Color(red: 232/255, green: 113/255, blue: 44/255), location: 1),
            ],
            startPoint: UnitPoint(x: 0.15, y: 0.15),
            endPoint: UnitPoint(x: 0.85, y: 0.85)
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

        return VStack(alignment: .leading, spacing: side * 0.006) {
            Text("ціль збору:")
                .font(PosterFont.plexMonoRegular.size(labelSize))
                .tracking(labelSize * 0.2)
                .textCase(.uppercase)
                .foregroundStyle(Self.peach)

            Text(goal)
                .campaignPosterElement(.target)
                .font(PosterFont.oswaldBold.size(side * 0.1))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .padding(.bottom, side * 0.006)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(Self.amber)
                        .frame(height: side * 0.008)
                }
                .fixedSize(horizontal: true, vertical: false)

            if let fraction = funding.fraction {
                progress(fraction: fraction, side: side)
            }
        }
    }

    /// Тут уже є бурштинова підкреслювальна лінія під сумою — смужка просто
    /// продовжує її думку: та сама вага, лише заповнена частково.
    private func progress(fraction: Double, side: CGFloat) -> some View {
        let labelSize = side * 0.028

        return VStack(alignment: .leading, spacing: side * 0.01) {
            PosterProgressBar(
                fraction: fraction,
                shape: Rectangle(),
                height: side * 0.008,
                track: .white.opacity(0.18),
                fill: Self.amber
            )

            if let collected = funding.collected {
                Text("зібрано \(collected)")
                    .campaignPosterFundingElement(.collected)
                    .font(PosterFont.plexMonoRegular.size(labelSize))
                    .tracking(labelSize * 0.16)
                    .textCase(.uppercase)
                    .foregroundStyle(Self.peach)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
        .padding(.top, side * 0.014)
        .frame(maxWidth: side * 0.54, alignment: .leading)
    }

    /// Збір закрито: підкреслення розростається під усю етикетку й стає
    /// плашкою, на якій і стоїть вигук.
    private func finished(side: CGFloat) -> some View {
        let labelSize = side * 0.032

        return VStack(alignment: .leading, spacing: side * 0.01) {
            Text(CampaignPosterFunding.finishedLabel)
                .campaignPosterFundingElement(.finished)
                .font(PosterFont.plexMonoRegular.size(labelSize))
                .tracking(labelSize * 0.2)
                .textCase(.uppercase)
                .foregroundStyle(Self.ink)
                .padding(.horizontal, side * 0.018)
                .padding(.vertical, side * 0.008)
                .background(Self.amber)

            if let collected = funding.collected {
                Text(collected)
                    .campaignPosterFundingElement(.collected)
                    .font(PosterFont.oswaldBold.size(side * 0.1))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
            }
        }
    }

    private static let ink = Color(red: 44/255, green: 24/255, blue: 8/255)

    private static let amber = Color(red: 247/255, green: 154/255, blue: 63/255)
    private static let peach = Color(red: 255/255, green: 208/255, blue: 168/255)
}

#Preview {
    PosterTemplatePreview { purpose, funding, photo in
        PosterA11TemplateView(purpose: purpose, funding: funding, viewProvider: photo)
    }
}
