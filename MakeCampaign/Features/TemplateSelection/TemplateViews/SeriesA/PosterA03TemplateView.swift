//
//  PosterA03TemplateView.swift
//  MakeCampaign
//

import SwiftUI

/// Набір A, `linearPurple_topCenter` — an editorial page: cream stock under a
/// faint dot screen, the photo filling the upper half, and the title set large
/// in Playfair with the goal ruled off beneath it in italic.
struct PosterA03TemplateView: View {
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
                    .padding(.horizontal, side * 0.05)
                    .padding(.top, side * 0.05)

                caption(side: side)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background {
                Self.cream.overlay {
                    PosterDotScreen(
                        color: Self.violet,
                        pitch: side * 0.026,
                        radius: side * 0.0024
                    )
                    .opacity(0.14)
                }
            }
        }
    }

    private func caption(side: CGFloat) -> some View {
        let purposeSize = side * 0.086

        return VStack(alignment: .leading, spacing: 0) {
            Text(purpose)
                .campaignPosterElement(.campaignTitle)
                .font(PosterFont.playfairExtraBold.size(purposeSize))
                .foregroundStyle(Self.violet)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.5)
                .frame(maxWidth: .infinity, alignment: .leading)

            if funding.isFinished {
                finished(side: side)
            } else if let goal = funding.goal {
                collecting(goal: goal, side: side)
            }
        }
        .padding(.horizontal, side * 0.05)
        .padding(.top, side * 0.04)
        .padding(.bottom, side * 0.05)
    }

    private func collecting(goal: String, side: CGFloat) -> some View {
        let labelSize = side * 0.035

        return VStack(alignment: .leading, spacing: side * 0.02) {
            VStack(alignment: .leading, spacing: side * 0.008) {
                HStack(alignment: .firstTextBaseline, spacing: side * 0.024) {
                    Text(funding.goalLabel)
                        .font(PosterFont.plexMonoRegular.size(labelSize))
                        .tracking(labelSize * 0.14)
                        .textCase(.uppercase)
                        .foregroundStyle(Self.aubergine)

                    Text(goal)
                        .campaignPosterElement(.target)
                        .font(PosterFont.playfairBoldItalic.size(side * 0.08))
                        .foregroundStyle(Self.nearBlack)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }

                if let supportingGoal = funding.supportingGoal {
                    Text(supportingGoal)
                        .font(PosterFont.plexMonoRegular.size(labelSize * 0.86))
                        .foregroundStyle(Self.aubergine)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }

            if let fraction = funding.fraction {
                progress(fraction: fraction, side: side)
            }
        }
        .padding(.trailing, side * 0.26)
        .modifier(VioletRule(side: side))
    }

    /// Смужка повторює товсту фіолетову лінію над собою — та сама вага, той
    /// самий колір, лише заповнена до досягнутої частки.
    private func progress(fraction: Double, side: CGFloat) -> some View {
        let labelSize = side * 0.030

        return VStack(alignment: .leading, spacing: side * 0.01) {
            PosterProgressBar(
                fraction: fraction,
                shape: Rectangle(),
                height: side * 0.012,
                track: Self.violet.opacity(0.2),
                fill: Self.violet
            )

            if let collected = funding.collected {
                Text("зібрано \(collected)")
                    .campaignPosterFundingElement(.collected)
                    .font(PosterFont.plexMonoRegular.size(labelSize))
                    .tracking(labelSize * 0.14)
                    .textCase(.uppercase)
                    .foregroundStyle(Self.aubergine)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
    }

    /// Збір закрито: фіолет сходить із лінії на плашку, і те, що було
    /// запитом, стає підсумком — курсивом Playfair, як і належить цій сторінці.
    private func finished(side: CGFloat) -> some View {
        let labelSize = side * 0.035

        return HStack(alignment: .firstTextBaseline, spacing: side * 0.024) {
            Text(CampaignPosterFunding.finishedLabel)
                .campaignPosterFundingElement(.finished)
                .font(PosterFont.plexMonoRegular.size(labelSize))
                .tracking(labelSize * 0.14)
                .textCase(.uppercase)
                .foregroundStyle(Self.cream)
                .padding(.horizontal, side * 0.02)
                .padding(.vertical, side * 0.008)
                .background(Self.violet)

            if let collected = funding.collected {
                Text(collected)
                    .campaignPosterFundingElement(.collected)
                    .font(PosterFont.playfairBoldItalic.size(side * 0.08))
                    .foregroundStyle(Self.nearBlack)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
        .padding(.trailing, side * 0.26)
        .modifier(VioletRule(side: side))
    }

    private struct VioletRule: ViewModifier {
        let side: CGFloat

        func body(content: Content) -> some View {
            content
                .padding(.top, side * 0.022)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Self.violet)
                        .frame(height: side * 0.005)
                }
                .padding(.top, side * 0.026)
        }

        private static let violet = Color(red: 107/255, green: 47/255, blue: 122/255)
    }

    private static let cream = Color(red: 246/255, green: 241/255, blue: 224/255)
    private static let violet = Color(red: 107/255, green: 47/255, blue: 122/255)
    private static let aubergine = Color(red: 58/255, green: 32/255, blue: 54/255)
    private static let nearBlack = Color(red: 34/255, green: 18/255, blue: 25/255)
}

#Preview {
    PosterTemplatePreview { purpose, funding, photo in
        PosterA03TemplateView(purpose: purpose, funding: funding, viewProvider: photo)
    }
}
