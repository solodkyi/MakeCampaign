import SwiftUI

struct EmeraldBlackGradientTemplateView: View {
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
            let imageSize = side * 0.58
            let padding = side * 0.045
            
            let purposeFontSize = side * 0.048
            let goalLabelFontSize = side * 0.052
            let goalValueFontSize = side * 0.066
            
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0/255, green: 150/255, blue: 136/255), // Teal/Emerald
                        Color(red: 12/255, green: 12/255, blue: 12/255)    // Near black
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                ZStack {
                    viewProvider()
                        .frame(width: imageSize, height: imageSize)
                        .clipShape(
                            Polygon(sides: 6)
                        )
                        .rotationEffect(.degrees(-8))
                        .offset(x: side * 0.01, y: side * 0.02)
                        .shadow(color: .black.opacity(0.45), radius: side * 0.018, x: side * 0.01, y: side * 0.01)
                        .overlay(
                            Polygon(sides: 6)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.5), .clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: side * 0.004
                                )
                                .rotationEffect(.degrees(-8))
                        )
                    
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
                            .padding(padding * 0.8)
                            .background(
                                RoundedRectangle(cornerRadius: side * 0.02)
                                    .fill(.black.opacity(0.55))
                                    .rotationEffect(.degrees(-6))
                            )
                            .frame(maxWidth: side * 0.42, alignment: .leading)
                            .rotationEffect(.degrees(6))
                            .offset(x: side * 0.02, y: side * 0.0)
                            
                            Spacer()
                        }
                        
                        Spacer()
                    }
                    .padding(.top, padding)
                    .padding(.leading, padding)
                    
                    if let goal {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                VStack(alignment: .trailing, spacing: side * 0.006) {
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
                                        .fill(.black.opacity(0.55))
                                        .rotationEffect(.degrees(-6))
                                )
                                .offset(x: side * 0.02, y: -side * 0.01)
                            }
                        }
                        .padding(.bottom, padding)
                        .padding(.trailing, padding)
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
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
                
                EmeraldBlackGradientTemplateView(
                    purpose: "Збір на прилади нічного бачення", goal: "900.000", viewProvider: {
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
                
                EmeraldBlackGradientTemplateView(
                    purpose: "Збір на прилади нічного бачення", goal: "900.000", viewProvider: {
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
                
                EmeraldBlackGradientTemplateView(
                    purpose: "Збір на прилади нічного бачення", goal: "900.000", viewProvider: {
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
                
                EmeraldBlackGradientTemplateView(
                    purpose: "Збір на прилади нічного бачення", goal: "900.000", viewProvider: {
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
                
                EmeraldBlackGradientTemplateView(
                    purpose: "Збір на прилади нічного бачення", goal: "900.000", viewProvider: {
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


