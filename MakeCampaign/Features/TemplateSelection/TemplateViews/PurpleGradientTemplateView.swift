//
//  PurpleGradientTemplateView.swift
//  MakeCampaign
//
//  Created by Andrii Solodkyi on 5/19/25.
//

import SwiftUI

struct PurpleGradientTemplateView: View {
    let purpose: String
    let goal: String
    
    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            let imageWidth = side * 885 / 1080
            let imageHeight = side * 422 / 1080
            let topSpacing = side * 93 / 1080
            let horizontalPadding = side * 98 / 1080
            let purposeTopPadding = side * 42 / 1080
            let betweenTextsSpacing = side * 36 / 1080
            let goalBottomPadding = side * 65 / 1080
            
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 90/255, green: 76/255, blue: 173/255),
                        Color(red: 78/255, green: 66/255, blue: 150/255),
                        Color(red: 37/255, green: 31/255, blue: 71/255)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer().frame(height: topSpacing)
                    
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: imageWidth, height: imageHeight)
                        .fixedSize()
                    
                    Spacer().frame(height: purposeTopPadding)
                    
                    HStack {
                        Text(purpose)
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                            .minimumScaleFactor(0.3)
                            .lineLimit(nil)
                        Spacer()
                    }
                    .padding(.horizontal, horizontalPadding)
                    
                    Spacer().frame(height: betweenTextsSpacing)
                    
                    Spacer()
                    
                    HStack {
                        Spacer()
                        Text(goal)
                            .minimumScaleFactor(0.3)
                            .lineLimit(1)
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.bottom, goalBottomPadding)
                }
                .frame(width: side, height: side, alignment: .bottom)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

#Preview {
    VStack {
        Spacer()
        PurpleGradientTemplateView(purpose: "Для забезпечення 5 ОМБр автомобілем для виконання задач", goal: "Ціль: 600.000 грн.")
            .frame(width: 1080/3, height: 1080/3)
        Spacer()
    }
}
