//
//  CyanMagentaGradientTemplateView.swift
//  MakeCampaign
//

import SwiftUI

/// `cyanMagentaRadial_squareTrailing` — a riso-print treatment: bone paper, two
/// overprinted ink circles bleeding off the top-left corner, and a square photo
/// backed by an offset cyan block.
///
/// The circles multiply into each other and into the paper, which is what gives
/// the overlap its third colour; drawing them opaque would flatten the effect.
struct CyanMagentaGradientTemplateView: View {
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

            ZStack(alignment: .topLeading) {
                Self.paper

                ink(side: side)

                VStack(alignment: .leading, spacing: 0) {
                    header(side: side)
                        .padding(.top, side * 0.22)

                    photo(side: side)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .frame(maxHeight: .infinity)
                        .padding(.vertical, side * 0.04)

                    caption(side: side)
                }
                .padding(side * 0.06)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }

    private func ink(side: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            Circle()
                .fill(Self.cyan)
                .frame(width: side * 0.46, height: side * 0.46)
                .opacity(0.85)
                .offset(x: -side * 0.12, y: -side * 0.12)

            Circle()
                .fill(Self.magenta)
                .frame(width: side * 0.34, height: side * 0.34)
                .opacity(0.8)
                .offset(x: side * 0.12, y: -side * 0.06)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .blendMode(.multiply)
    }

    private func header(side: CGFloat) -> some View {
        let kickerSize = side * 0.023
        let purposeSize = side * 0.06

        return VStack(alignment: .leading, spacing: side * 0.014) {
            Text("збір")
                .font(PosterFont.plexMonoRegular.size(kickerSize))
                .tracking(kickerSize * 0.3)
                .textCase(.uppercase)
                .foregroundStyle(Self.magentaInk)

            Text(purpose)
                .campaignPosterElement(.campaignTitle)
                .font(PosterFont.oswaldSemiBold.size(purposeSize))
                .lineSpacing(purposeSize * 0.04)
                .textCase(.uppercase)
                .foregroundStyle(Self.charcoal)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: side * 0.7, alignment: .leading)
        }
    }

    private func photo(side: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(Self.cyan)
                .offset(x: side * 0.024, y: side * 0.024)

            PosterPhoto(Rectangle(), photo: viewProvider)
        }
        .aspectRatio(1.0, contentMode: .fit)
                    .frame(maxWidth: side * 0.54, maxHeight: side * 0.54)
    }

    @ViewBuilder
    private func caption(side: CGFloat) -> some View {
        if let goal {
            let labelSize = side * 0.024

            HStack(alignment: .firstTextBaseline, spacing: side * 0.024) {
                Text("ціль збору:")
                    .font(PosterFont.plexMonoRegular.size(labelSize))
                    .tracking(labelSize * 0.16)
                    .textCase(.uppercase)
                    .foregroundStyle(Self.magentaInk)

                Text(goal)
                    .campaignPosterElement(.target)
                    .font(PosterFont.oswaldBold.size(side * 0.084))
                    .foregroundStyle(Self.charcoal)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .padding(.trailing, side * 0.26)
        }
    }

    private static let paper = Color(red: 244/255, green: 244/255, blue: 239/255)
    private static let cyan = Color(red: 22/255, green: 200/255, blue: 216/255)
    private static let magenta = Color(red: 229/255, green: 56/255, blue: 156/255)
    private static let magentaInk = Color(red: 165/255, green: 33/255, blue: 143/255)
    private static let charcoal = Color(red: 20/255, green: 20/255, blue: 26/255)
}

#Preview {
    PosterTemplatePreview { purpose, goal, photo in
        CyanMagentaGradientTemplateView(purpose: purpose, goal: goal, viewProvider: photo)
    }
}
