//
//  PosterA12TemplateView.swift
//  MakeCampaign
//

import SwiftUI

/// Набір A, `linearEmeraldBlack_hexagonTrailing` — a night field speckled with
/// dots, the photo cut to a hexagon lying on its side, and the goal boxed in a
/// thin emerald rule.
struct PosterA12TemplateView: View {
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
                header(side: side)

                PosterPhoto(PosterHexagonHorizontal(), photo: viewProvider)
                    .aspectRatio(0.9, contentMode: .fit)
                    .frame(maxWidth: side * 0.54, maxHeight: side * 0.54 / 0.9)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .frame(maxHeight: .infinity)
                    .padding(.vertical, side * 0.035)

                caption(side: side)
            }
            .padding(side * 0.06)
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background {
                background.overlay {
                    PosterDotScreen(
                        color: .white.opacity(0.22),
                        pitch: side * 0.022,
                        radius: side * 0.0024
                    )
                    .opacity(0.35)
                }
            }
        }
    }

    private var background: some View {
        LinearGradient(
            stops: [
                .init(color: Self.pitch, location: 0),
                .init(color: Color(red: 16/255, green: 40/255, blue: 29/255), location: 0.55),
                .init(color: Color(red: 11/255, green: 125/255, blue: 85/255), location: 1),
            ],
            startPoint: UnitPoint(x: 0.67, y: 0.03),
            endPoint: UnitPoint(x: 0.33, y: 0.97)
        )
    }

    private func header(side: CGFloat) -> some View {
        let kickerSize = side * 0.023
        let purposeSize = side * 0.058

        return VStack(alignment: .leading, spacing: side * 0.014) {
            Text("збір")
                .font(PosterFont.plexMonoRegular.size(kickerSize))
                .tracking(kickerSize * 0.3)
                .textCase(.uppercase)
                .foregroundStyle(Self.emerald)

            Text(purpose)
                .campaignPosterElement(.campaignTitle)
                .font(PosterFont.oswaldMedium.size(purposeSize))
                .lineSpacing(purposeSize * 0.08)
                .foregroundStyle(Self.frost)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: side * 0.62, alignment: .leading)
        }
    }

    @ViewBuilder
    private func caption(side: CGFloat) -> some View {
        if let goal {
            let labelSize = side * 0.024

            HStack(alignment: .firstTextBaseline, spacing: side * 0.02) {
                Text("ціль збору:")
                    .font(PosterFont.plexMonoRegular.size(labelSize))
                    .tracking(labelSize * 0.14)
                    .textCase(.uppercase)
                    .foregroundStyle(Self.emerald)

                Spacer(minLength: 0)

                Text(goal)
                    .campaignPosterElement(.target)
                    .font(PosterFont.plexMonoSemiBold.size(side * 0.062))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .padding(.leading, side * 0.03)
            .padding(.trailing, side * 0.26)
            .padding(.vertical, side * 0.026)
            .background(Self.pitch)
            .overlay {
                Rectangle()
                    .stroke(Self.emerald, lineWidth: side * 0.0025)
            }
        }
    }

    private static let pitch = Color(red: 10/255, green: 15/255, blue: 12/255)
    private static let emerald = Color(red: 111/255, green: 227/255, blue: 176/255)
    private static let frost = Color(red: 240/255, green: 246/255, blue: 242/255)
}

#Preview {
    PosterTemplatePreview { purpose, goal, photo in
        PosterA12TemplateView(purpose: purpose, goal: goal, viewProvider: photo)
    }
}
