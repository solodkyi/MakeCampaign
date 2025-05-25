import SwiftUI

struct GoldBlackGradientTemplateView: View {
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
            let imageSize = side * 0.58
            let padding = side * 0.045
            
            let purposeFontSize = side * 0.048
            let goalLabelFontSize = side * 0.052
            let goalValueFontSize = side * 0.066
            
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 255/255, green: 215/255, blue: 0/255),   // #FFD700 (Gold)
                        Color(red: 20/255, green: 20/255, blue: 20/255)     // #141414 (Dark Black)
                    ]),
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                )
                .ignoresSafeArea()
                
                ZStack {
                    // Hexagonal image positioned centrally with slight offset and rotation
                    viewProvider()
                        .frame(width: imageSize, height: imageSize)
                        .clipShape(
                            Polygon(sides: 6)
                        )
                        .rotationEffect(.degrees(8))
                        .offset(x: -side * 0.02, y: side * 0.02)
                        .shadow(color: .black.opacity(0.45), radius: side * 0.018, x: side * 0.01, y: side * 0.01)
                        .overlay(
                            Polygon(sides: 6)
                                .stroke(
                                    LinearGradient(
                                        colors: [.yellow.opacity(0.6), .clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: side * 0.004
                                )
                                .rotationEffect(.degrees(8))
                        )
                    
                    // Purpose text positioned diagonally in top-left with semi-transparent background
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
                                Capsule()
                                    .fill(.black.opacity(0.6))
                            )
                            .frame(maxWidth: side * 0.42, alignment: .leading)
                            .rotationEffect(.degrees(-6))
                            .offset(x: -side * 0.02, y: side * 0.01)
                            
                            Spacer()
                        }
                        
                        Spacer()
                    }
                    .padding(.top, padding)
                    .padding(.leading, padding)
                    
                    // Goal positioned in bottom-right with angled background
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
                                        .fill(.black.opacity(0.6))
                                        .rotationEffect(.degrees(6))
                                )
                                .offset(x: side * 0.02, y: -side * 0.01)
                            }
                        }
                        .padding(.bottom, padding)
                        .padding(.trailing, padding)
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped() // Ensure content doesn't overflow
            }
        }
    }
}

// Custom Polygon shape for hexagon
struct Polygon: Shape {
    let sides: Int
    
    func path(in rect: CGRect) -> Path {
        guard sides >= 3 else { return Path() }
        
        let center = CGPoint(x: rect.width / 2, y: rect.height / 2)
        let radius = min(rect.width, rect.height) / 2
        let angle = .pi * 2 / Double(sides)
        
        var path = Path()
        
        for i in 0..<sides {
            let x = center.x + radius * cos(Double(i) * angle - .pi / 2)
            let y = center.y + radius * sin(Double(i) * angle - .pi / 2)
            let point = CGPoint(x: x, y: y)
            
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        
        path.closeSubpath()
        return path
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            VStack(spacing: 10) {
                Text("Size: 1080/3 (360x360)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                GoldBlackGradientTemplateView(
                    purpose: "Збір на дрони для захисників", goal: "1.500.000", viewProvider: {
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
                
                GoldBlackGradientTemplateView(
                    purpose: "Збір на дрони для захисників", goal: "1.500.000", viewProvider: {
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
                
                GoldBlackGradientTemplateView(
                    purpose: "Збір на дрони для захисників", goal: "1.500.000", viewProvider: {
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
                
                GoldBlackGradientTemplateView(
                    purpose: "Збір на дрони для захисників", goal: "1.500.000", viewProvider: {
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
                
                GoldBlackGradientTemplateView(
                    purpose: "Збір на дрони для захисників", goal: "1.500.000", viewProvider: {
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