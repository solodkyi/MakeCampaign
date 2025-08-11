import SwiftUI

struct MintIndigoGradientTemplateView: View {
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
            let imageSize = side * 0.6
            let padding = side * 0.05
            
            let purposeFontSize = side * 0.052
            let goalLabelFontSize = side * 0.055
            let goalValueFontSize = side * 0.07
            
            ZStack {
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0/255, green: 210/255, blue: 135/255), // #00D287 (Vivid Mint)
                        Color(red: 10/255, green: 37/255, blue: 64/255)    // #0A2540 (Deep Navy)
                    ]),
                    center: .topLeading,
                    startRadius: side * 0.1,
                    endRadius: side * 1.2
                )
                .ignoresSafeArea()
                
                ZStack {
                    ZStack {
                        viewProvider()
                            .frame(width: imageSize * 1.5, height: imageSize * 1.5)
                            .clipped()
                    }
                    .frame(width: imageSize, height: imageSize)
                    .clipShape(Circle())
                    .rotationEffect(.degrees(-12))
                    .offset(x: -side * 0.15, y: -side * 0.08)
                    .shadow(color: .black.opacity(0.3), radius: side * 0.01, x: side * 0.005, y: side * 0.005)
                    
                    VStack {
                        HStack {
                            Spacer()
                            VStack(alignment: .trailing, spacing: side * 0.01) {
                                Text(purpose)
                                    .font(.custom("Roboto-Bold", size: purposeFontSize))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.trailing)
                                    .lineLimit(nil)
                                    .minimumScaleFactor(0.8)
                            }
                            .padding(padding * 0.8)
                            .background(
                                RoundedRectangle(cornerRadius: side * 0.02)
                                    .fill(.black.opacity(0.4))
                            )
                            .frame(maxWidth: side * 0.55, alignment: .trailing)
                        }
                        
                        Spacer()
                        
                        if let goal {
                            HStack {
                                VStack(alignment: .leading, spacing: side * 0.008) {
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
                
                MintIndigoGradientTemplateView(
                    purpose: "Гуманітарна підтримка", goal: "700.000", viewProvider: {
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
                
                MintIndigoGradientTemplateView(
                    purpose: "Гуманітарна підтримка", goal: "700.000", viewProvider: {
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
                
                MintIndigoGradientTemplateView(
                    purpose: "Гуманітарна підтримка", goal: "700.000", viewProvider: {
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
                
                MintIndigoGradientTemplateView(
                    purpose: "Гуманітарна підтримка", goal: "700.000", viewProvider: {
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
                
                MintIndigoGradientTemplateView(
                    purpose: "Гуманітарна підтримка", goal: "700.000", viewProvider: {
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


