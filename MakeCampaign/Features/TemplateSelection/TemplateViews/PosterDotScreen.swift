//
//  PosterDotScreen.swift
//  MakeCampaign
//

import SwiftUI

/// A grid of dots laid over whatever it covers.
///
/// The pitch is passed in as a fraction of the poster width by every caller, so
/// the texture reads the same from a strip thumbnail up to a 1080pt export
/// rather than turning into a solid tint at small sizes.
struct PosterDotScreen: View {
    let color: Color
    let pitch: CGFloat
    let radius: CGFloat

    var body: some View {
        Canvas { context, size in
            var y = pitch / 2
            while y < size.height + pitch {
                var x = pitch / 2
                while x < size.width + pitch {
                    context.fill(
                        Path(
                            ellipseIn: CGRect(
                                x: x - radius,
                                y: y - radius,
                                width: radius * 2,
                                height: radius * 2
                            )
                        ),
                        with: .color(color)
                    )
                    x += pitch
                }
                y += pitch
            }
        }
        .allowsHitTesting(false)
    }
}
