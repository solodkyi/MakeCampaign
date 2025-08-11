import SwiftUI
import UIKit

struct IndigoOrangeGradientTemplateView: View {
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
            let side = geometry.size.width
            let imageSize = side * 0.56
            let padding = side * 0.045
            
            let purposeFontSize = side * 0.05
            let goalLabelFontSize = side * 0.052
            let goalValueFontSize = side * 0.066
            
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 63/255, green: 81/255, blue: 181/255),   // Indigo 500
                        Color(red: 255/255, green: 152/255, blue: 0/255)     // Orange 600
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: padding) {
                    HStack {
                        Text(purpose)
                            .font(.custom("Roboto-Bold", size: purposeFontSize))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                            .lineLimit(3)
                            .minimumScaleFactor(0.8)
                            .padding(padding * 0.8)
                            .background(
                                RoundedRectangle(cornerRadius: side * 0.02)
                                    .fill(Color.white.opacity(0.1))
                            )
                        Spacer()
                    }
                    .padding(.horizontal, padding)
                    .padding(.top, padding)
                    
                    Spacer(minLength: 0)
                    
                    HStack {
                        Spacer()
                        viewProvider()
                            .frame(width: imageSize, height: imageSize)
                            .clipShape(RoundedRectangle(cornerRadius: side * 0.04))
                            .overlay(
                                RoundedRectangle(cornerRadius: side * 0.04)
                                    .stroke(.white.opacity(0.25), lineWidth: side * 0.004)
                            )
                            .shadow(color: .black.opacity(0.3), radius: side * 0.015, x: 0, y: side * 0.01)
                            .padding(.trailing, padding)
                    }
                    
                    if let goal {
                        HStack {
                            VStack(alignment: .leading, spacing: side * 0.006) {
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
                                RoundedRectangle(cornerRadius: side * 0.04)
                                    .stroke(.white.opacity(0.25), lineWidth: side * 0.004)
                            )
                            .padding(.leading, padding)
                            Spacer()
                        }
                        .padding(.bottom, padding)
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
    }
}

#if DEBUG
#Preview {
    ScrollView {
        VStack(spacing: 20) {
            VStack(spacing: 10) {
                Text("Size: 1080/3 (360x360)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                IndigoOrangeGradientTemplateView(
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
                
                IndigoOrangeGradientTemplateView(
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
                
                IndigoOrangeGradientTemplateView(
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
                
                IndigoOrangeGradientTemplateView(
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
                
                IndigoOrangeGradientTemplateView(
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
#endif


