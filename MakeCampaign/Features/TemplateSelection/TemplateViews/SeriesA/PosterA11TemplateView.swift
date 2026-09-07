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
        if let goal {
            let labelSize = side * 0.024

            VStack(alignment: .leading, spacing: side * 0.006) {
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
            }
        }
    }

    private static let amber = Color(red: 247/255, green: 154/255, blue: 63/255)
    private static let peach = Color(red: 255/255, green: 208/255, blue: 168/255)
}

#Preview {
    PosterTemplatePreview { purpose, goal, photo in
        PosterA11TemplateView(purpose: purpose, goal: goal, viewProvider: photo)
    }
}
