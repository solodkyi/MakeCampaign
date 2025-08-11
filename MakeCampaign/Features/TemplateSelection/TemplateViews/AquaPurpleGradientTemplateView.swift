import SwiftUI

struct AquaPurpleGradientTemplateView: View {
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
            let imageWidth = side * 0.55
            let imageHeight = side * 0.4
            let padding = side * 0.04
            
            let purposeFontSize = side * 0.05
            let goalLabelFontSize = side * 0.053
            let goalValueFontSize = side * 0.068
            
            ZStack {
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0/255, green: 229/255, blue: 255/255),   // #00E5FF (Aqua)
                        Color(red: 74/255, green: 20/255, blue: 140/255)    // #4A148C (Deep Purple)
                    ]),
                    center: .bottomTrailing,
                    startRadius: side * 0.2,
                    endRadius: side * 1.4
                )
                .ignoresSafeArea()
                
                ZStack {
                    viewProvider()
                        .frame(width: imageWidth, height: imageHeight)
                        .clipShape(RoundedRectangle(cornerRadius: side * 0.03))
                        .rotationEffect(.degrees(10))
                        .offset(x: -side * 0.08, y: side * 0.12)
                        .shadow(color: .black.opacity(0.4), radius: side * 0.015, x: side * 0.008, y: side * 0.008)
                    
                    VStack {
                        HStack {
                            VStack(alignment: .leading, spacing: side * 0.008) {
                                Text(purpose)
                                    .font(.custom("Roboto-Bold", size: purposeFontSize))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(nil)
                                    .minimumScaleFactor(0.8)
                            }
                            .padding(padding * 0.9)
                            .background(
                                RoundedRectangle(cornerRadius: side * 0.025)
                                    .fill(.black.opacity(0.5))
                            )
                            .frame(maxWidth: side * 0.58, alignment: .leading)
                            
                            Spacer()
                        }
                        
                        Spacer()
                        
                        if let goal {
                            HStack {
                                Spacer()
                                VStack(alignment: .trailing, spacing: side * 0.005) {
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
                                .padding(padding * 0.9)
                                .background(
                                    RoundedRectangle(cornerRadius: side * 0.025)
                                        .fill(.black.opacity(0.5))
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
                
                AquaPurpleGradientTemplateView(
                    purpose: "Підтримка медичного забезпечення", goal: "800.000", viewProvider: {
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
                
                AquaPurpleGradientTemplateView(
                    purpose: "Підтримка медичного забезпечення", goal: "800.000", viewProvider: {
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
                
                AquaPurpleGradientTemplateView(
                    purpose: "Підтримка медичного забезпечення", goal: "800.000", viewProvider: {
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
                
                AquaPurpleGradientTemplateView(
                    purpose: "Підтримка медичного забезпечення", goal: "800.000", viewProvider: {
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
                
                AquaPurpleGradientTemplateView(
                    purpose: "Підтримка медичного забезпечення", goal: "800.000", viewProvider: {
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


