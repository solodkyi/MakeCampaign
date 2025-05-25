//
//  TealPurpleGradientTemplateView.swift
//  MakeCampaign
//
//  Created by Andrii Solodkyi on 5/19/25.
//

import SwiftUI

struct TealPurpleGradientTemplateView: View {
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
            let imageSize = side * 0.6
            let padding = side * 0.05
            
            let purposeFontSize = side * 0.052
            let goalLabelFontSize = side * 0.055
            let goalValueFontSize = side * 0.07
            
            ZStack {
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color(red: 32/255, green: 178/255, blue: 170/255), // #20B2AA (Light Sea Green)
                        Color(red: 75/255, green: 0/255, blue: 130/255)    // #4B0082 (Indigo)
                    ]),
                    center: .topTrailing,
                    startRadius: side * 0.1,
                    endRadius: side * 1.2
                )
                .ignoresSafeArea()
                
                ZStack {
                    // Static circular template with fixed position and rotation
                    ZStack {
                        // Image content that can be repositioned within the circular mask
                        viewProvider()
                            .frame(width: imageSize * 1.5, height: imageSize * 1.5) // Larger frame for repositioning
                            .clipped()
                    }
                    .frame(width: imageSize, height: imageSize)
                    .clipShape(Circle())
                    .rotationEffect(.degrees(15))
                    .offset(x: side * 0.15, y: -side * 0.1)
                    .shadow(color: .black.opacity(0.3), radius: side * 0.01, x: side * 0.005, y: side * 0.005)
                    
                    // Purpose text with semi-transparent background
                    VStack {
                        HStack {
                            VStack(alignment: .leading, spacing: side * 0.01) {
                                Text(purpose)
                                    .font(.custom("Roboto-Bold", size: purposeFontSize))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(nil)
                                    .minimumScaleFactor(0.8)
                            }
                            .padding(padding * 0.8)
                            .background(
                                RoundedRectangle(cornerRadius: side * 0.02)
                                    .fill(.black.opacity(0.4))
                            )
                            .frame(maxWidth: side * 0.55, alignment: .leading)
                            
                            Spacer()
                        }
                        
                        Spacer()
                        
                        // Goal positioned in bottom trailing corner
                        if let goal {
                            HStack {
                                Spacer()
                                VStack(alignment: .trailing, spacing: side * 0.008) {
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
                                .padding(padding * 0.8)
                                .background(
                                    RoundedRectangle(cornerRadius: side * 0.02)
                                        .fill(.black.opacity(0.4))
                                )
                            }
                        }
                    }
                    .padding(padding)
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
                
                TealPurpleGradientTemplateView(
                    purpose: "Допомога для військових підрозділів у забезпеченні", goal: "800.000", viewProvider: {
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
                
                TealPurpleGradientTemplateView(
                    purpose: "Допомога для військових підрозділів у забезпеченні", goal: "800.000", viewProvider: {
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
                
                TealPurpleGradientTemplateView(
                    purpose: "Допомога для військових підрозділів у забезпеченні", goal: "800.000", viewProvider: {
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
                
                TealPurpleGradientTemplateView(
                    purpose: "Допомога для військових підрозділів у забезпеченні", goal: "800.000", viewProvider: {
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
                
                TealPurpleGradientTemplateView(
                    purpose: "Допомога для військових підрозділів у забезпеченні", goal: "800.000", viewProvider: {
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
