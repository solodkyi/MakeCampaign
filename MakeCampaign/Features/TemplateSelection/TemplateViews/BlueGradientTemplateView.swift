//
//  BlueGradientTemplateView.swift
//  MakeCampaign
//
//  Created by Andrii Solodkyi on 5/19/25.
//

import SwiftUI

struct BlueGradientTemplateView: View {
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
            let imageSize = side * 0.5
            let padding = side * 0.04
            
            let purposeFontSize = side * 0.048
            let goalLabelFontSize = side * 0.055
            let goalValueFontSize = side * 0.065
            
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 25/255, green: 25/255, blue: 112/255), // #191970 (Midnight Blue)
                        Color(red: 135/255, green: 206/255, blue: 235/255) // #87CEEB (Sky Blue)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: padding) {
                    Spacer()
                    Text(purpose)
                        .font(.custom("Roboto-Bold", size: purposeFontSize))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .padding(.horizontal, padding)
                        .padding(.top, padding * 0.5)
                                        
                    viewProvider()
                        .frame(width: imageSize, height: imageSize)
                        .clipShape(RoundedRectangle(cornerRadius: side * 0.025))
                        .overlay(
                            RoundedRectangle(cornerRadius: side * 0.025)
                                .stroke(.white.opacity(0.3), lineWidth: side * 0.003)
                        )
                        .shadow(color: .black.opacity(0.2), radius: side * 0.01, x: 0, y: side * 0.005)
                    
                    // Goal at bottom
                    if let goal {
                        VStack(spacing: side * 0.005) {
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
                        .padding(.bottom, padding)
                    }
                }
                .padding(.bottom)
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
                
                BlueGradientTemplateView(
                    purpose: "Підтримка захисників України", goal: "1.200.000", viewProvider: {
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
                
                BlueGradientTemplateView(
                    purpose: "Підтримка захисників України", goal: "1.200.000", viewProvider: {
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
                
                BlueGradientTemplateView(
                    purpose: "Підтримка захисників України", goal: "1.200.000", viewProvider: {
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
                
                BlueGradientTemplateView(
                    purpose: "Підтримка захисників України", goal: "1.200.000", viewProvider: {
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
                
                BlueGradientTemplateView(
                    purpose: "Підтримка захисників України", goal: "1.200.000", viewProvider: {
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
