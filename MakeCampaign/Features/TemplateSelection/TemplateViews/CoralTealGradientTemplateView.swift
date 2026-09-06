//
//  CoralTealGradientTemplateView.swift
//  MakeCampaign
//

import SwiftUI

/// `linearCoralTeal_trailing` — flat coral ground with a deep teal disc pushed
/// off the trailing edge, and the photo cut to an arch that opens toward it.
struct CoralTealGradientTemplateView: View {
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

            HStack(spacing: 0) {
                copy(side: side)
                    .frame(width: geometry.size.width * 0.54, alignment: .leading)

                photo(side: side, height: geometry.size.height)
                    .frame(width: geometry.size.width * 0.46)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background {
                Self.coral.overlay(alignment: .trailing) {
                    Circle()
                        .fill(Self.teal)
                        .frame(width: side * 0.76, height: side * 0.76)
                        .offset(x: side * 0.14)
                }
            }
        }
    }

    private func copy(side: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: side * 0.03) {
            Text(purpose.uppercased())
                .campaignPosterElement(.campaignTitle)
                .font(PosterFont.oswaldBold.size(side * 0.066))
                .lineSpacing(side * 0.066 * 0.02)
                .foregroundStyle(Self.ember)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)

            if let goal {
                let labelSize = side * 0.022

                VStack(alignment: .leading, spacing: side * 0.006) {
                    Text("ціль збору:")
                        .font(PosterFont.plexMonoRegular.size(labelSize))
                        .tracking(labelSize * 0.2)
                        .textCase(.uppercase)
                        .foregroundStyle(Self.rust)

                    Text(goal)
                        .campaignPosterElement(.target)
                        .font(PosterFont.oswaldBold.size(side * 0.08))
                        .foregroundStyle(Self.shell)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
        }
        .padding(.leading, side * 0.06)
        .padding(.trailing, side * 0.04)
        .padding(.vertical, side * 0.06)
    }

    private func photo(side: CGFloat, height: CGFloat) -> some View {
        let boxWidth = side * 0.46 - side * 0.06
        let boxHeight = height - side * 0.16
        let radius = min(boxWidth, boxHeight) / 2

        return PosterPhoto(UnevenRoundedRectangle( topLeadingRadius: radius, bottomLeadingRadius: radius, bottomTrailingRadius: 0, topTrailingRadius: 0 ), photo: viewProvider)
            .padding(.trailing, side * 0.06)
            .padding(.vertical, side * 0.08)
    }

    private static let coral = Color(red: 255/255, green: 106/255, blue: 77/255)
    private static let teal = Color(red: 13/255, green: 95/255, blue: 99/255)
    private static let ember = Color(red: 42/255, green: 11/255, blue: 5/255)
    private static let rust = Color(red: 93/255, green: 26/255, blue: 13/255)
    private static let shell = Color(red: 255/255, green: 246/255, blue: 240/255)
}

#Preview {
    PosterTemplatePreview { purpose, goal, photo in
        CoralTealGradientTemplateView(purpose: purpose, goal: goal, viewProvider: photo)
    }
}
