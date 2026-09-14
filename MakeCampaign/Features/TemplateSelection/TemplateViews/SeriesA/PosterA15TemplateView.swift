//
//  PosterA15TemplateView.swift
//  MakeCampaign
//

import SwiftUI

/// Набір A, `linearCoralTeal_trailing` — coral washing diagonally into teal, the
/// title set very large down the left, and the goal in a dark teal pill.
struct PosterA15TemplateView: View {
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
                    .frame(width: geometry.size.width * 0.58, alignment: .leading)

                PosterPhoto(Rectangle(), photo: viewProvider)
                    .frame(width: geometry.size.width * 0.42)
                    .frame(maxHeight: .infinity)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(background)
        }
    }

    private var background: some View {
        LinearGradient(
            stops: [
                .init(color: Color(red: 255/255, green: 106/255, blue: 77/255), location: 0),
                .init(color: Color(red: 224/255, green: 74/255, blue: 60/255), location: 0.4),
                .init(color: Color(red: 15/255, green: 111/255, blue: 116/255), location: 1),
            ],
            startPoint: UnitPoint(x: 0.05, y: 0.29),
            endPoint: UnitPoint(x: 0.95, y: 0.71)
        )
    }

    private func copy(side: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(purpose.uppercased())
                .campaignPosterElement(.campaignTitle)
                .font(PosterFont.oswaldBold.size(side * 0.076))
                .foregroundStyle(Self.shell)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.5)
                .frame(maxWidth: .infinity, alignment: .leading)

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

        return VStack(alignment: .leading, spacing: side * 0.014) {
            Text(funding.goalLabel)
                .font(PosterFont.plexMonoRegular.size(labelSize))
                .tracking(labelSize * 0.16)
                .textCase(.uppercase)
                .foregroundStyle(Self.seafoam)

            // Ціль і підпис під нею тримаються тісніше, ніж крок капсули:
            // так другий рядок читається як пояснення, а не як новий пункт.
            VStack(alignment: .leading, spacing: side * 0.006) {
                Text(goal)
                    .campaignPosterElement(.target)
                    .font(PosterFont.oswaldBold.size(side * 0.064))
                    .lineSpacing(side * 0.064 * 0.02)
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.5)

                // Підпис — найдовший рядок блоку, тож він стискається в межах
                // колонки замість того, щоб розсувати її.
                if let supportingGoal = funding.supportingGoal {
                    Text(supportingGoal)
                        .font(PosterFont.plexMonoRegular.size(labelSize * 0.86))
                        .foregroundStyle(Self.seafoam.opacity(0.85))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }

            if let fraction = funding.fraction {
                progress(fraction: fraction, side: side)
            }
        }
        .modifier(Lozenge(side: side, isTall: Self.lozengeIsTall(funding: funding)))
    }

    /// Смужка лежить усередині бірюзової капсули, тож бере піну — той самий
    /// колір, яким набрано етикетку над нею.
    private func progress(fraction: Double, side: CGFloat) -> some View {
        let labelSize = side * 0.027

        return VStack(alignment: .leading, spacing: side * 0.008) {
            PosterProgressBar(
                fraction: fraction,
                height: side * 0.01,
                track: Self.seafoam.opacity(0.28),
                fill: Self.seafoam
            )

            if let collected = funding.collected {
                Text("зібрано \(collected)")
                    .campaignPosterFundingElement(.collected)
                    .font(PosterFont.plexMonoRegular.size(labelSize))
                    .tracking(labelSize * 0.14)
                    .textCase(.uppercase)
                    .foregroundStyle(Self.seafoam.opacity(0.85))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
    }

    /// Збір закрито: капсула світлішає до піни, і напис читається глибокою
    /// бірюзою — та сама форма, вивернута навиворіт.
    private func finished(side: CGFloat) -> some View {
        let labelSize = side * 0.030

        return VStack(alignment: .leading, spacing: 0) {
            Text(CampaignPosterFunding.finishedLabel)
                .campaignPosterFundingElement(.finished)
                .font(PosterFont.plexMonoRegular.size(labelSize))
                .tracking(labelSize * 0.16)
                .textCase(.uppercase)
                .foregroundStyle(Self.deepTeal)

            if let collected = funding.collected {
                Text(collected)
                    .campaignPosterFundingElement(.collected)
                    .font(PosterFont.oswaldBold.size(side * 0.064))
                    .lineSpacing(side * 0.064 * 0.02)
                    .foregroundStyle(Self.deepTeal)
                    .minimumScaleFactor(0.5)
            }
        }
        .modifier(Lozenge(side: side, fill: Self.seafoam))
    }

    private struct Lozenge: ViewModifier {
        let side: CGFloat
        var fill: Color = Color(red: 4/255, green: 52/255, blue: 58/255)

        /// Капсула гарна, поки напис у ній — один-два рядки: її торці тоді
        /// лише обіймають текст. Коли під ціллю стають ще й смужка з підписом,
        /// висота росте, а з нею й радіус — дуги заходять на рядки й зрізають
        /// їх. Високий блок тому лягає в заокруглений прямокутник: та сама
        /// м'яка мова, але кути більше не залежать від висоти.
        var isTall = false

        func body(content: Content) -> some View {
            content
                .padding(.horizontal, side * 0.03)
                .padding(.vertical, side * 0.024)
                .background(fill, in: shape)
        }

        private var shape: AnyShape {
            isTall
                ? AnyShape(RoundedRectangle(cornerRadius: side * 0.07, style: .continuous))
                : AnyShape(Capsule())
        }
    }

    /// Блок високий, щойно під ціллю з'являється бодай один додатковий
    /// рядок — підпис загальної цілі або смужка поступу.
    static func lozengeIsTall(funding: CampaignPosterFunding) -> Bool {
        funding.supportingGoal != nil || funding.fraction != nil
    }

    private static let shell = Color(red: 255/255, green: 246/255, blue: 240/255)
    private static let deepTeal = Color(red: 4/255, green: 52/255, blue: 58/255)
    private static let seafoam = Color(red: 143/255, green: 224/255, blue: 216/255)
}

#Preview {
    PosterTemplatePreview { purpose, funding, photo in
        PosterA15TemplateView(purpose: purpose, funding: funding, viewProvider: photo)
    }
}
