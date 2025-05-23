//
//  YellowBlueGradientTemplateView.swift
//  MakeCampaign
//
//  Created by Andrii Solodkyi on 5/19/25.
//

import SwiftUI

struct YellowBlueGradientTemplateView: View {
    let goal: String
    let purpose: String
    
    var viewProvider: () -> AnyView
    
    init(purpose: String, goal: String, viewProvider: @escaping () -> some View = { Color.clear }) {
        self.purpose = purpose
        self.goal = goal
        self.viewProvider = { AnyView(viewProvider()) }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            let imageWidth = side * 0.38
            let imageHeight = side * 0.55
            let horizontalPadding = side * 0.04
            let verticalPadding = side * 0.08
            
            let goalLabelFontSize = side * 0.055
            let goalValueFontSize = side * 0.075
            let purposeFontSize = side * 0.05
            
            ZStack {
                AngularGradient(
                  stops: [
                    Gradient.Stop(color: Color(red: 1, green: 0.72, blue: 0.06), location: 0.5),
                    Gradient.Stop(color: Color(red: 0.38, green: 0.43, blue: 1), location: 0.65),
                  ],
                  center: UnitPoint(x: 0.73, y: 0.44),
                  angle: Angle(degrees: -34)
                )
                
                VStack(alignment: .leading, spacing: side * 0.01) {
                    HStack(alignment: .bottom, spacing: horizontalPadding) {
                        VStack(alignment: .leading, spacing: side * 0.008) {
                            Text("ціль збору:")
                                .font(.custom("Roboto-Bold", size: goalLabelFontSize))
                                .foregroundColor(.white)
                                .minimumScaleFactor(0.7)
                                .lineLimit(1)
                            Text(goal)
                                .font(.custom("Roboto-Bold", size: goalValueFontSize))
                                .foregroundColor(.white)
                                .minimumScaleFactor(0.7)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        viewProvider()
                            .frame(width: imageWidth, height: imageHeight)
                            .clipped()
                            .cornerRadius(side * 0.02)
                    }
                    .padding(.top, verticalPadding)
                    
                    Text(purpose)
                        .font(.custom("Roboto-Bold", size: purposeFontSize))
                        .foregroundColor(.white)
                        .lineLimit(3)
                        .minimumScaleFactor(0.7)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, verticalPadding * 0.8)
                }
                .padding(.horizontal, horizontalPadding)
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
                
                YellowBlueGradientTemplateView(
                    purpose: "текст текст тексттекст текст тексттекст текст тексттекст текст текст", goal: "000.000"
                ) {
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
                
                YellowBlueGradientTemplateView(
                    purpose: "текст текст тексттекст текст тексттекст текст тексттекст текст текст", goal: "000.000"
                ) {
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
                
                YellowBlueGradientTemplateView(
                    purpose: "текст текст тексттекст текст тексттекст текст тексттекст текст текст", goal: "000.000"
                ) {
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
                
                YellowBlueGradientTemplateView(
                    purpose: "текст текст тексттекст текст тексттекст текст тексттекст текст текст", goal: "000.000"
                ) {
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
                
                YellowBlueGradientTemplateView(
                    purpose: "текст текст тексттекст текст тексттекст текст тексттекст текст текст", goal: "000.000"
                ) {
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

