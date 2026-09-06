//
//  PinkGradientTemplateView.swift
//  MakeCampaign
//

import SwiftUI

/// `pinkAngular_topCenter` — a polaroid tilted on a swept pink ground, with the
/// title on a black slug and the goal in a yellow capsule.
///
/// The card, the slug and the capsule are each rotated by a different small
/// amount; matching them would read as a mistake rather than a collage.
struct PinkGradientTemplateView: View {
    let purpose: String
    let goal: String?

    var viewProvider: () -> AnyView

    init(purpose: String, goal: String?, viewProvider: @escaping () -> some View = { Color.clear }) {
        self.purpose = purpose
        self.goal = goal
        self.viewProvider = { AnyView(viewProvider()) }
    }

    var body: some View {
        GeometryReader { geometry in
            let side = geometry.size.width

            VStack(alignment: .leading, spacing: 0) {
                polaroid(side: side)
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: .infinity)
                    .padding(.bottom, side * 0.04)

                caption(side: side)
            }
            .padding(side * 0.06)
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(background)
        }
    }

    private var background: some View {
        AngularGradient(
            stops: [
                .init(color: Self.hot, location: 0),
                .init(color: Self.blush, location: 120.0 / 360.0),
                .init(color: Self.wine, location: 300.0 / 360.0),
                .init(color: Self.hot, location: 1),
            ],
            center: UnitPoint(x: 0.7, y: 0.2),
            angle: .degrees(40)
        )
    }

    private func polaroid(side: CGFloat) -> some View {
        PosterPhoto(Rectangle(), photo: viewProvider)
            .padding(.horizontal, side * 0.02)
            .padding(.top, side * 0.02)
            .padding(.bottom, side * 0.06)
            .background(.white)
            .aspectRatio(1.0, contentMode: .fit)
                    .frame(maxWidth: side * 0.66, maxHeight: side * 0.66)
            .rotationEffect(.degrees(-4))
            .shadow(
                color: Color(red: 60/255, green: 5/255, blue: 30/255).opacity(0.35),
                radius: side * 0.05,
                x: 0,
                y: side * 0.02
            )
    }

    private func caption(side: CGFloat) -> some View {
        let purposeSize = side * 0.05

        return VStack(alignment: .leading, spacing: side * 0.026) {
            Text(purpose)
                .campaignPosterElement(.campaignTitle)
                .font(PosterFont.oswaldSemiBold.size(purposeSize))
                .lineSpacing(purposeSize * 0.1)
                .textCase(.uppercase)
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.6)
                .padding(.horizontal, side * 0.03)
                .padding(.vertical, side * 0.02)
                .background(Self.tar)
                .frame(maxWidth: side * 0.84, alignment: .leading)
                .rotationEffect(.degrees(-1.5))

            if let goal {
                let labelSize = side * 0.022

                HStack(alignment: .firstTextBaseline, spacing: side * 0.022) {
                    Text("ціль збору:")
                        .font(PosterFont.plexMonoRegular.size(labelSize))
                        .tracking(labelSize * 0.14)
                        .textCase(.uppercase)
                        .foregroundStyle(Self.amberInk)

                    Text(goal)
                        .campaignPosterElement(.target)
                        .font(PosterFont.oswaldBold.size(side * 0.064))
                        .foregroundStyle(Self.tar)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                .padding(.horizontal, side * 0.03)
                .padding(.vertical, side * 0.02)
                .background(Self.lemon, in: Capsule())
            }
        }
    }

    private static let hot = Color(red: 255/255, green: 79/255, blue: 147/255)
    private static let blush = Color(red: 255/255, green: 138/255, blue: 184/255)
    private static let wine = Color(red: 109/255, green: 11/255, blue: 56/255)
    private static let tar = Color(red: 23/255, green: 2/255, blue: 12/255)
    private static let lemon = Color(red: 255/255, green: 225/255, blue: 79/255)
    private static let amberInk = Color(red: 109/255, green: 59/255, blue: 0/255)
}

#Preview {
    PosterTemplatePreview { purpose, goal, photo in
        PinkGradientTemplateView(purpose: purpose, goal: goal, viewProvider: photo)
    }
}
