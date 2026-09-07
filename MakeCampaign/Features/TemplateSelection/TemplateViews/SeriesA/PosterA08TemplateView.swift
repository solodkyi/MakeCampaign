//
//  PosterA08TemplateView.swift
//  MakeCampaign
//

import SwiftUI

/// Набір A, `angularYellowBlue_trailing` — a technical sheet: near-black under a
/// faint measuring grid, everything boxed in hairline rules, set in Plex Mono
/// with the goal in yellow.
struct PosterA08TemplateView: View {
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

            VStack(alignment: .leading, spacing: side * 0.03) {
                header(side: side)

                HStack(alignment: .top, spacing: side * 0.03) {
                    PosterPhoto(Rectangle(), photo: viewProvider)
                        .padding(side * 0.008)
                        .overlay {
                            Rectangle()
                                .stroke(.white.opacity(0.5), lineWidth: side * 0.003)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    caption(side: side)
                }
                .frame(maxHeight: .infinity)
            }
            .padding(side * 0.05)
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background {
                Self.ink.overlay { grid(side: side) }
            }
        }
    }

    /// The measuring grid: hairlines every 3.2% of the poster width.
    private func grid(side: CGFloat) -> some View {
        let pitch = side * 0.032

        return Canvas { context, size in
            let line = GraphicsContext.Shading.color(.white.opacity(0.09))
            var x: CGFloat = 0
            while x < size.width {
                context.fill(Path(CGRect(x: x, y: 0, width: 1, height: size.height)), with: line)
                x += pitch
            }
            var y: CGFloat = 0
            while y < size.height {
                context.fill(Path(CGRect(x: 0, y: y, width: size.width, height: 1)), with: line)
                y += pitch
            }
        }
        .allowsHitTesting(false)
    }

    private func header(side: CGFloat) -> some View {
        let kickerSize = side * 0.023
        let purposeSize = side * 0.044

        return VStack(alignment: .leading, spacing: side * 0.014) {
            Text("збір")
                .font(PosterFont.plexMonoRegular.size(kickerSize))
                .tracking(kickerSize * 0.28)
                .textCase(.uppercase)
                .foregroundStyle(Self.yellow)

            Text(purpose)
                .campaignPosterElement(.campaignTitle)
                .font(PosterFont.plexMonoMedium.size(purposeSize))
                .lineSpacing(purposeSize * 0.25)
                .foregroundStyle(Self.paper)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(side * 0.03)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay {
            Rectangle()
                .stroke(Self.yellow, lineWidth: side * 0.003)
        }
    }

    @ViewBuilder
    private func caption(side: CGFloat) -> some View {
        if let goal {
            let labelSize = side * 0.024

            VStack(alignment: .leading, spacing: side * 0.01) {
                Text("ціль збору:")
                    .font(PosterFont.plexMonoRegular.size(labelSize))
                    .tracking(labelSize * 0.16)
                    .textCase(.uppercase)
                    .foregroundStyle(Self.grey)

                Text(goal)
                    .campaignPosterElement(.target)
                    .font(PosterFont.oswaldBold.size(side * 0.072))
                    .lineSpacing(side * 0.072 * 0.02)
                    .foregroundStyle(Self.yellow)
                    .minimumScaleFactor(0.5)
            }
            .padding(.top, side * 0.01)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }

    private static let ink = Color(red: 16/255, green: 16/255, blue: 20/255)
    private static let yellow = Color(red: 242/255, green: 225/255, blue: 76/255)
    private static let paper = Color(red: 243/255, green: 243/255, blue: 239/255)
    private static let grey = Color(red: 157/255, green: 157/255, blue: 149/255)
}

#Preview {
    PosterTemplatePreview { purpose, goal, photo in
        PosterA08TemplateView(purpose: purpose, goal: goal, viewProvider: photo)
    }
}
