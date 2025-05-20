//
//  YellowBlueGradientTemplateView.swift
//  MakeCampaign
//
//  Created by Andrii Solodkyi on 5/19/25.
//

import SwiftUI

struct YellowBlueGradientTemplateView: View {
    let goal: String
    let description: String
    
    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            let imageWidth = side * 0.38
            let imageHeight = side * 0.55
            let horizontalPadding = side * 0.04
            let verticalPadding = side * 0.08
            
            ZStack {
                AngularGradient(
                  stops: [
                    Gradient.Stop(color: Color(red: 1, green: 0.72, blue: 0.06), location: 0.5),
                    Gradient.Stop(color: Color(red: 0.38, green: 0.43, blue: 1), location: 0.65),
                  ],
                  center: UnitPoint(x: 0.73, y: 0.44),
                  angle: Angle(degrees: -34)
                )
                VStack(alignment: .leading) {
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading) {
                            Text("ціль збору:")
                                .font(.custom("Roboto-Bold", size: 28)
                                )
                                .foregroundColor(.white)
                                .minimumScaleFactor(0.3)
                                .lineLimit(1)
                            Text(goal)
                                .font(.custom("Roboto-Bold", size: 38)
                                )
                                .foregroundColor(.white)
                                .minimumScaleFactor(0.2)
                                .lineLimit(1)
                        }
                        Spacer()
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: imageWidth, height: imageHeight)
                            .padding(.horizontal, horizontalPadding)
                    }
                    .padding(.top, verticalPadding)
                    Text(description)
                        .font(.custom("Roboto-Bold", size: 28)
                        )
                        .foregroundColor(.white)
                        .lineLimit(nil)
                        .minimumScaleFactor(0.2)
                        .padding(.bottom)
                }
                .padding(.horizontal)
            }
        }
    }
}

#Preview {
    YellowBlueGradientTemplateView(
        goal: "000.000",
        description: "текст текст тексттекст текст тексттекст текст тексттекст текст текст"
    )
    .frame(width: 1080/3, height: 1350/3)
}

