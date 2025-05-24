//
//  PurpleGradientTemplateView.swift
//  MakeCampaign
//
//  Created by Andrii Solodkyi on 5/19/25.
//

import SwiftUI

struct PurpleGradientTemplateView: View {
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
            let side = min(geometry.size.width, geometry.size.height)
            let imageWidth = side * 885 / 1080
            let imageHeight = side * 422 / 1080
            let topSpacing = side * 93 / 1080
            let purposeTopPadding = side * 42 / 1080
            let betweenTextsSpacing = side * 36 / 1080
            let goalBottomPadding = side * 65 / 1080
            
            let purposeFontSize = side * 0.06
            let goalFontSize = side * 0.08
            
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
                    
                    viewProvider()
                        .frame(width: imageWidth, height: imageHeight)
                        .clipped()
                    
                    Spacer().frame(height: purposeTopPadding)
                    
                    HStack {
                        Text(purpose)
                            .multilineTextAlignment(.center)
                            .font(.custom("Roboto-Bold", size: purposeFontSize))
                            .foregroundColor(.white)
                            .minimumScaleFactor(0.8)
                            .lineLimit(nil)
                    }
                    .padding(.horizontal)
                    
                    Spacer().frame(height: betweenTextsSpacing)
                    
                    Spacer()
                    
                    if let goal {
                        HStack {
                            Spacer()
                            Text("Ціль: \(goal)")
                                .font(.custom("Roboto-Bold", size: goalFontSize))
                                .multilineTextAlignment(.trailing)
                                .minimumScaleFactor(0.8)
                                .lineLimit(1)
                                .foregroundColor(.white)
                            
                        }
                        .padding(.horizontal)
                        .padding(.bottom, goalBottomPadding)
                    }
                }
                .frame(width: side, height: side, alignment: .bottom)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            VStack(spacing: 10) {
                Text("Size: 1080/3 (360x360)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                PurpleGradientTemplateView(purpose: "Для забезпечення 5 ОМБр автомобілем", goal: "600.000") {
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
                
                PurpleGradientTemplateView(purpose: "Для забезпечення 5 ОМБр автомобілем", goal: "600.000") {
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
                
                PurpleGradientTemplateView(purpose: "Для забезпечення 5 ОМБр автомобілем", goal: "600.000") {
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
                
                PurpleGradientTemplateView(purpose: "Для забезпечення 5 ОМБр автомобілем", goal: "600.000") {
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
                
                PurpleGradientTemplateView(purpose: "Для забезпечення 5 ОМБр автомобілем", goal: "600.000") {
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
