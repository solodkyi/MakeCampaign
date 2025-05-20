//
//  RedBlackGradientTemplateView.swift
//  MakeCampaign
//
//  Created by Andrii Solodkyi on 5/20/25.
//

import SwiftUI

struct RedBlackGradientTemplateView: View {
    let goal: String
    let description: String
    
    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            let verticalPadding = side * 0.06
            let horizontalPadding = side * 0.05
            
            ZStack {
                RadialGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(hex: "#E73535"), location: 0),
                        .init(color: Color(hex: "#0C0C0C"), location: 1)
                    ]),
                    center: UnitPoint(x: 0.89, y: 0.23),
                    startRadius: 0,
                    endRadius: side * 1.5
                )
                .ignoresSafeArea()
                
                HStack(spacing: 0) {
                    VStack(alignment: .leading) {
                        Text(description)
                            .multilineTextAlignment(.leading)
                            .font(.custom("Roboto-Bold", size: 25))
                            .foregroundColor(.white)
                            .minimumScaleFactor(0.2)
                            .lineLimit(nil)
                            .padding(horizontalPadding)
                    }
  
                        VStack(alignment: .trailing) {
                            Rectangle()
                                .fill(Color.white)
                            Spacer()
                            
                            VStack(alignment: .leading, spacing: 5) {
                                Text("ціль збору:")
                                    .font(.custom("Roboto-Bold", size: 60))
                                    .lineLimit(1)
                                    .foregroundColor(.white)
                                    .minimumScaleFactor(0.3)
                                
                                Text(goal)
                                    .font(.custom("Roboto-Bold", size: 60))
                                    .lineLimit(1)
                                    .foregroundColor(.white)
                                    .minimumScaleFactor(0.3)
                            }
                            .padding(.bottom, verticalPadding)
                    }
                        .padding(.trailing, horizontalPadding*2)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

#Preview {
    RedBlackGradientTemplateView(
        goal: "000.000",
        description: "текст текст текст текст"
    )
    .frame(width: 1080/3, height: 1350/3)
}

