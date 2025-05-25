import SwiftUI

struct CyanMagentaGradientTemplateView: View {
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
            let imageWidth = side * 0.55
            let imageHeight = side * 0.4
            let padding = side * 0.04
            
            let purposeFontSize = side * 0.05
            let goalLabelFontSize = side * 0.053
            let goalValueFontSize = side * 0.068
            
            ZStack {
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0/255, green: 255/255, blue: 255/255),    // #00FFFF (Cyan)
                        Color(red: 255/255, green: 0/255, blue: 255/255)     // #FF00FF (Magenta)
                    ]),
                    center: .bottomLeading,
                    startRadius: side * 0.2,
                    endRadius: side * 1.4
                )
                .ignoresSafeArea()
                
                ZStack {
                    // Image positioned diagonally with rotation and rounded rectangle clipping
                    viewProvider()
                        .frame(width: imageWidth, height: imageHeight)
                        .clipShape(RoundedRectangle(cornerRadius: side * 0.03))
                        .rotationEffect(.degrees(-12))
                        .offset(x: side * 0.08, y: side * 0.12)
                        .shadow(color: .black.opacity(0.4), radius: side * 0.015, x: side * 0.008, y: side * 0.008)
                    
                    // Purpose text with semi-transparent background - positioned top right
                    VStack {
                        HStack {
                            Spacer()
                            VStack(alignment: .trailing, spacing: side * 0.008) {
                                Text(purpose)
                                    .font(.custom("Roboto-Bold", size: purposeFontSize))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.trailing)
                                    .lineLimit(nil)
                                    .minimumScaleFactor(0.8)
                            }
                            .padding(padding * 0.9)
                            .background(
                                RoundedRectangle(cornerRadius: side * 0.025)
                                    .fill(.black.opacity(0.5))
                            )
                            .frame(maxWidth: side * 0.58, alignment: .trailing)
                        }
                        
                        Spacer()
                        
                        // Goal positioned in bottom left corner
                        if let goal {
                            HStack {
                                VStack(alignment: .leading, spacing: side * 0.005) {
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
                                
                                Spacer()
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
                
                CyanMagentaGradientTemplateView(
                    purpose: "Технічна підтримка для бригади", goal: "950.000", viewProvider: {
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
                
                CyanMagentaGradientTemplateView(
                    purpose: "Технічна підтримка для бригади", goal: "950.000", viewProvider: {
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
                
                CyanMagentaGradientTemplateView(
                    purpose: "Технічна підтримка для бригади", goal: "950.000", viewProvider: {
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
                
                CyanMagentaGradientTemplateView(
                    purpose: "Технічна підтримка для бригади", goal: "950.000", viewProvider: {
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
                
                CyanMagentaGradientTemplateView(
                    purpose: "Технічна підтримка для бригади", goal: "950.000", viewProvider: {
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