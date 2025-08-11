import SwiftUI

struct CoralTealGradientTemplateView: View {
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
            let imageSize = side * 0.52
            let padding = side * 0.045
            
            let purposeFontSize = side * 0.05
            let goalLabelFontSize = side * 0.053
            let goalValueFontSize = side * 0.068
            
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 255/255, green: 127/255, blue: 80/255),   // Coral
                        Color(red: 0/255, green: 128/255, blue: 128/255)     // Teal
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                ZStack {
                    // Rounded image at leading side
                    HStack {
                        viewProvider()
                            .frame(width: imageSize, height: imageSize)
                            .clipShape(RoundedRectangle(cornerRadius: side * 0.035))
                            .overlay(
                                RoundedRectangle(cornerRadius: side * 0.035)
                                    .stroke(.white.opacity(0.25), lineWidth: side * 0.004)
                            )
                            .shadow(color: .black.opacity(0.25), radius: side * 0.012, x: 0, y: side * 0.006)
                        
                        Spacer()
                    }
                    .padding(.leading, padding)
                    
                    // Purpose and goal stacked on trailing side
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
                                    .padding(padding * 0.8)
                                    .background(
                                        RoundedRectangle(cornerRadius: side * 0.02)
                                            .fill(.black.opacity(0.35))
                                    )
                                    .frame(maxWidth: side * 0.52, alignment: .trailing)
                            }
                        }
                        
                        Spacer()
                        
                        if let goal {
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
                                        .fill(.black.opacity(0.35))
                                )
                                .padding(.trailing, padding)
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
                
                CoralTealGradientTemplateView(
                    purpose: "Комунікації та зв'язок", goal: "750.000", viewProvider: {
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
                
                CoralTealGradientTemplateView(
                    purpose: "Комунікації та зв'язок", goal: "750.000", viewProvider: {
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
                
                CoralTealGradientTemplateView(
                    purpose: "Комунікації та зв'язок", goal: "750.000", viewProvider: {
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
                
                CoralTealGradientTemplateView(
                    purpose: "Комунікації та зв'язок", goal: "750.000", viewProvider: {
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
                
                CoralTealGradientTemplateView(
                    purpose: "Комунікації та зв'язок", goal: "750.000", viewProvider: {
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


