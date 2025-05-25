//
//  PinkGradientTemplateView.swift
//  MakeCampaign
//
//  Created by Andrii Solodkyi on 5/19/25.
//

import SwiftUI

struct PinkGradientTemplateView: View {
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
            let side = geometry.size.width // Use full width instead of minimum
            let imageHeight = side * 0.45
            let imageWidth = side * 0.8
            let horizontalPadding = side * 0.06
            let verticalSpacing = side * 0.03
            
            let purposeFontSize = side * 0.055
            let goalLabelFontSize = side * 0.06
            let goalValueFontSize = side * 0.075
            
            ZStack {
                AngularGradient(
                    stops: [
                        Gradient.Stop(color: Color(red: 255/255, green: 20/255, blue: 147/255), location: 0.0), // #FF1493 (Deep Pink)
                        Gradient.Stop(color: Color(red: 199/255, green: 21/255, blue: 133/255), location: 0.4), // #C71585 (Medium Violet Red)
                        Gradient.Stop(color: Color(red: 255/255, green: 192/255, blue: 203/255), location: 1.0)  // #FFC0CB (Pink)
                    ],
                    center: .bottomLeading,
                    angle: .degrees(45)
                )
                
                VStack(spacing: verticalSpacing) {
                    viewProvider()
                        .frame(width: imageWidth, height: imageHeight)
                        .clipShape(RoundedRectangle(cornerRadius: side * 0.02))
                        .padding(.top, verticalSpacing)
                    
                    Text(purpose)
                        .font(.custom("Roboto-Bold", size: purposeFontSize))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .minimumScaleFactor(0.8)
                        .padding(.horizontal, horizontalPadding)
                    
                    Spacer()
                    
                    if let goal {
                        VStack(spacing: side * 0.008) {
                            Text("ціль збору:")
                                .font(.custom("Roboto-Bold", size: goalLabelFontSize))
                                .foregroundColor(.white)
                                .minimumScaleFactor(0.8)
                                .lineLimit(1)
                            
                            Text(goal)
                                .font(.custom("Roboto-Bold", size: goalValueFontSize))
                                .foregroundColor(.white)
                                .minimumScaleFactor(0.8)
                                .lineLimit(1)
                        }
                        .padding(.bottom, verticalSpacing)
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
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
                
                PinkGradientTemplateView(
                    purpose: "Для забезпечення 5 ОМБр важливою технікою", goal: "600.000", viewProvider: {
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
                )
                .frame(width: 1080/3, height: 1080/3)
            }
            
            VStack(spacing: 10) {
                Text("Size: 1080/4 (270x270)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                PinkGradientTemplateView(
                    purpose: "Для забезпечення 5 ОМБр важливою технікою", goal: "600.000", viewProvider: {
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
                )
                .frame(width: 1080/4, height: 1080/4)
            }
            
            VStack(spacing: 10) {
                Text("Size: 1080/5 (216x216)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                PinkGradientTemplateView(
                    purpose: "Для забезпечення 5 ОМБр важливою технікою", goal: "600.000", viewProvider: {
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
                )
                .frame(width: 1080/5, height: 1080/5)
            }
            
            VStack(spacing: 10) {
                Text("Size: 1080/6 (180x180)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                PinkGradientTemplateView(
                    purpose: "Для забезпечення 5 ОМБр важливою технікою", goal: "600.000", viewProvider: {
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
                )
                .frame(width: 1080/6, height: 1080/6)
            }
            
            VStack(spacing: 10) {
                Text("Size: 1080/7 (154x154)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                PinkGradientTemplateView(
                    purpose: "Для забезпечення 5 ОМБр важливою технікою", goal: "600.000", viewProvider: {
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
                )
                .frame(width: 1080/7, height: 1080/7)
            }
        }
        .padding()
    }
} 
