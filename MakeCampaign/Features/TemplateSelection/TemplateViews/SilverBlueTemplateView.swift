//
//  SilverBlueTemplateView.swift
//  MakeCampaign
//
//  Created by Andrii Solodkyi on 5/19/25.
//

import SwiftUI

struct SilverBlueTemplateView: View {
    let goal: String?
    let purpose: String
    var viewProvider: () -> AnyView
    
    init(purpose: String, goal: String?, viewProvider: @escaping () -> some View = { Color.clear }) {
        self.purpose = purpose
        self.goal = goal
        self.viewProvider = { AnyView(viewProvider()) }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let side = geometry.size.width // Use full width instead of minimum
            let horizontalPadding = side * 0.05
            let verticalPadding = side * 0.06
            let bottomTextSpacing = side * 0.02
            let imageWidth = side * 838/1080
            let imageHeight = side * 432/1080
            
            let goalFontSize = side * 0.08
            let purposeFontSize = side * 0.055
            
            ZStack {
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(hex: "#95C5E5"), location: 0),
                        .init(color: Color(hex: "#88B4D1"), location: 0.235),
                        .init(color: Color(hex: "#8ABFE2"), location: 0.559),
                        .init(color: Color(hex: "#386786"), location: 1)
                    ]),
                    startPoint: UnitPoint(x: 0.016, y: 1),
                    endPoint: UnitPoint(x: 0.94, y: 1)
                )
                .ignoresSafeArea()
                
                VStack(alignment: .trailing) {
                    HStack {
                        Spacer()
                        viewProvider()
                            .frame(width: imageWidth, height: imageHeight)
                            .clipped()
                            .padding(.top, verticalPadding)
                    }
                    .padding(.leading, 3*horizontalPadding)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: bottomTextSpacing) {
                        if let goal {
                            Text("Збір на \(goal)")
                                .font(.custom("Roboto-Bold", size: goalFontSize))
                                .foregroundColor(.white)
                                .minimumScaleFactor(0.8)
                        }
                        Text(purpose)
                            .multilineTextAlignment(.trailing)
                            .font(.custom("Roboto-Bold", size: purposeFontSize))
                            .minimumScaleFactor(0.8)
                            .foregroundColor(.white)
                            .lineLimit(nil)
                    }
                    .padding(.top, verticalPadding/2)
                    .padding(.bottom, verticalPadding * 1.3)
                    .padding(.leading, 3*horizontalPadding)
                    .padding(.trailing, horizontalPadding)
                }
            }
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            VStack(spacing: 10) {
                Text("Size: 1080/3 (360x360)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                SilverBlueTemplateView(
                    purpose: "текст текст тексттекст текст тексттекст текст ", goal: "000.000") {
                        if let imageData = Campaign.mock1.image?.raw, let uiImage = UIImage(data: imageData) {
                            return AnyView(
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                            )
                        } else {
                            return AnyView(Rectangle().fill(Color.red))
                        }
                    }
                .frame(width: 1080/3, height: 1080/3)
            }
            
            VStack(spacing: 10) {
                Text("Size: 1080/4 (270x270)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                SilverBlueTemplateView(
                    purpose: "текст текст тексттекст текст тексттекст текст ", goal: "000.000") {
                        if let imageData = Campaign.mock1.image?.raw, let uiImage = UIImage(data: imageData) {
                            return AnyView(
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                            )
                        } else {
                            return AnyView(Rectangle().fill(Color.red))
                        }
                    }
                .frame(width: 1080/4, height: 1080/4)
            }
            
            VStack(spacing: 10) {
                Text("Size: 1080/5 (216x216)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                SilverBlueTemplateView(
                    purpose: "текст текст тексттекст текст тексттекст текст ", goal: "000.000") {
                        if let imageData = Campaign.mock1.image?.raw, let uiImage = UIImage(data: imageData) {
                            return AnyView(
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                            )
                        } else {
                            return AnyView(Rectangle().fill(Color.red))
                        }
                    }
                .frame(width: 1080/5, height: 1080/5)
            }
            
            VStack(spacing: 10) {
                Text("Size: 1080/6 (180x180)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                SilverBlueTemplateView(
                    purpose: "текст текст тексттекст текст тексттекст текст ", goal: "000.000") {
                        if let imageData = Campaign.mock1.image?.raw, let uiImage = UIImage(data: imageData) {
                            return AnyView(
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                            )
                        } else {
                            return AnyView(Rectangle().fill(Color.red))
                        }
                    }
                .frame(width: 1080/6, height: 1080/6)
            }
            
            VStack(spacing: 10) {
                Text("Size: 1080/7 (154x154)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                SilverBlueTemplateView(
                    purpose: "текст текст тексттекст текст тексттекст текст ", goal: "000.000") {
                        if let imageData = Campaign.mock1.image?.raw, let uiImage = UIImage(data: imageData) {
                            return AnyView(
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                            )
                        } else {
                            return AnyView(Rectangle().fill(Color.red))
                        }
                    }
                .frame(width: 1080/7, height: 1080/7)
            }
        }
        .padding()
    }
}
