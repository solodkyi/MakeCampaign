//
//  BlueGradientTemplateView.swift
//  MakeCampaign
//
//  Created by Andrii Solodkyi on 5/19/25.
//

import SwiftUI

/// `blueLinear_center` — a centred, symmetrical composition: a double hairline
/// frame, a circular photo, and the goal figure set in Playfair below a rule.
///
/// All geometry is expressed as a fraction of the container width, mirroring the
/// `cqw` units the design is authored in, so the composition holds from a
/// thumbnail up to a 1080pt export and across square, portrait and story ratios.
struct BlueGradientTemplateView: View {
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

            VStack(spacing: 0) {
                kicker(side: side)

                photo(side: side)
                    .frame(maxHeight: .infinity)
                    .padding(.vertical, side * 0.03)

                caption(side: side)
            }
            .padding(side * 0.06)
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(background)
            .overlay(frame(inset: side * 0.04, opacity: 0.28, side: side))
            .overlay(frame(inset: side * 0.052, opacity: 0.14, side: side))
        }
    }

    private var background: some View {
        LinearGradient(
            stops: [
                .init(color: Color(red: 11/255, green: 18/255, blue: 48/255), location: 0),
                .init(color: Color(red: 22/255, green: 38/255, blue: 94/255), location: 0.7),
                .init(color: Color(red: 43/255, green: 76/255, blue: 150/255), location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func frame(inset: CGFloat, opacity: Double, side: CGFloat) -> some View {
        Rectangle()
            .stroke(.white.opacity(opacity), lineWidth: side * 0.002)
            .padding(inset)
    }

    private func kicker(side: CGFloat) -> some View {
        let size = side * 0.024

        return Text("збір")
            .font(PosterFont.plexMonoRegular.size(size))
            .tracking(size * 0.4)
            .textCase(.uppercase)
            .foregroundStyle(Self.accent)
    }

    private func photo(side: CGFloat) -> some View {
        PosterPhoto(Circle(), photo: viewProvider)
            .aspectRatio(1.0, contentMode: .fit)
                    .frame(maxWidth: side * 0.54, maxHeight: side * 0.54)
    }

    @ViewBuilder
    private func caption(side: CGFloat) -> some View {
        let purposeSize = side * 0.046

        VStack(spacing: side * 0.02) {
            Text(purpose.uppercased())
                .campaignPosterElement(.campaignTitle)
                .font(PosterFont.oswaldRegular.size(purposeSize))
                .tracking(purposeSize * 0.02)
                .lineSpacing(purposeSize * 0.16)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: side * 0.76)

            if let goal {
                let labelSize = side * 0.021

                VStack(spacing: side * 0.004) {
                    Text("ціль збору:")
                        .font(PosterFont.plexMonoRegular.size(labelSize))
                        .tracking(labelSize * 0.24)
                        .textCase(.uppercase)
                        .foregroundStyle(Self.accent)

                    Text(goal)
                        .campaignPosterElement(.target)
                        .font(PosterFont.playfairBold.size(side * 0.09))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                .padding(.top, side * 0.02)
                .frame(maxWidth: .infinity)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(.white.opacity(0.4))
                        .frame(height: side * 0.002)
                }
            }
        }
    }

    private static let accent = Color(red: 169/255, green: 194/255, blue: 245/255)
}

#Preview {
    PosterTemplatePreview { purpose, goal, photo in
        BlueGradientTemplateView(purpose: purpose, goal: goal, viewProvider: photo)
    }
}
