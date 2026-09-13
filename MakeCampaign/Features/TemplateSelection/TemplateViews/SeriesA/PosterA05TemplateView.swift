//
//  PosterA05TemplateView.swift
//  MakeCampaign
//

import SwiftUI

/// Набір A, `pinkAngular_topCenter` — a swept rose ground, the photo held in a
/// thick cream border, and the title on a ribbon notched at both ends.
struct PosterA05TemplateView: View {
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

            VStack(spacing: side * 0.035) {
                PosterPhoto(Rectangle(), photo: viewProvider)
                    .padding(side * 0.014)
                    .background(Self.cream)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                ribbon(side: side)

                caption(side: side)
            }
            .padding(side * 0.05)
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(background)
        }
    }

    private var background: some View {
        AngularGradient(
            stops: [
                .init(color: Self.blush, location: 0),
                .init(color: Color(red: 232/255, green: 116/255, blue: 159/255), location: 110.0 / 360.0),
                .init(color: Color(red: 124/255, green: 47/255, blue: 82/255), location: 250.0 / 360.0),
                .init(color: Self.blush, location: 1),
            ],
            center: UnitPoint(x: 0.3, y: 0.3),
            angle: .degrees(210)
        )
    }

    private func ribbon(side: CGFloat) -> some View {
        let purposeSize = side * 0.052

        return Text(purpose)
            .campaignPosterElement(.campaignTitle)
            .font(PosterFont.oswaldSemiBold.size(purposeSize))
            .lineSpacing(purposeSize * 0.08)
            .foregroundStyle(Self.wine)
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.6)
            .padding(.horizontal, side * 0.04)
            .padding(.vertical, side * 0.03)
            .frame(maxWidth: .infinity)
            .background(
                Self.cream,
                in: PosterNotchedBanner(
                    notch: side * 0.03,
                    notchesLeading: true,
                    notchesTrailing: true
                )
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
        let labelSize = side * 0.034

        return VStack(spacing: side * 0.006) {
            Text("ціль збору:")
                .font(PosterFont.plexMonoRegular.size(labelSize))
                .tracking(labelSize * 0.2)
                .textCase(.uppercase)
                .foregroundStyle(Self.deepWine)

            Text(goal)
                .campaignPosterElement(.target)
                .font(PosterFont.oswaldBold.size(side * 0.095))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .shadow(color: Self.deepWine.opacity(0.5), radius: side * 0.014, y: side * 0.004)

            if let fraction = funding.fraction {
                progress(fraction: fraction, side: side)
            }
        }
    }

    /// Композиція тут симетрична, тож і смужка коротка та центрована —
    /// рум'янець на глибокому вині.
    private func progress(fraction: Double, side: CGFloat) -> some View {
        let labelSize = side * 0.028

        return VStack(spacing: side * 0.01) {
            PosterProgressBar(
                fraction: fraction,
                height: side * 0.012,
                track: Self.deepWine.opacity(0.45),
                fill: Self.blush
            )
            .frame(width: side * 0.46)

            if let collected = funding.collected {
                Text("зібрано \(collected)")
                    .campaignPosterFundingElement(.collected)
                    .font(PosterFont.plexMonoRegular.size(labelSize))
                    .tracking(labelSize * 0.14)
                    .textCase(.uppercase)
                    .foregroundStyle(Self.blush)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
        .padding(.top, side * 0.014)
    }

    /// Збір закрито: рум'янець виходить із тіні у власну капсулу, і вигук
    /// стоїть там, де раніше стояла етикетка цілі.
    private func finished(side: CGFloat) -> some View {
        let labelSize = side * 0.034

        return VStack(spacing: side * 0.01) {
            Text(CampaignPosterFunding.finishedLabel)
                .campaignPosterFundingElement(.finished)
                .font(PosterFont.plexMonoRegular.size(labelSize))
                .tracking(labelSize * 0.2)
                .textCase(.uppercase)
                .foregroundStyle(Self.deepWine)
                .padding(.horizontal, side * 0.024)
                .padding(.vertical, side * 0.01)
                .background(Self.blush, in: Capsule())

            if let collected = funding.collected {
                Text(collected)
                    .campaignPosterFundingElement(.collected)
                    .font(PosterFont.oswaldBold.size(side * 0.095))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .shadow(color: Self.deepWine.opacity(0.5), radius: side * 0.014, y: side * 0.004)
            }
        }
    }

    private static let cream = Color(red: 253/255, green: 243/255, blue: 247/255)
    private static let blush = Color(red: 247/255, green: 200/255, blue: 221/255)
    private static let wine = Color(red: 74/255, green: 22/255, blue: 49/255)
    private static let deepWine = Color(red: 59/255, green: 15/255, blue: 38/255)
}

#Preview {
    PosterTemplatePreview { purpose, funding, photo in
        PosterA05TemplateView(purpose: purpose, funding: funding, viewProvider: photo)
    }
}
