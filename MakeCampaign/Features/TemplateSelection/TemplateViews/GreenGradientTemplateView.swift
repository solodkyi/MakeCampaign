import SwiftUI

struct GreenGradientTemplateView: View {
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
            let leftWidth = side * 0.5
            let imageInset: CGFloat = side * 0.08
            let spacing: CGFloat = side * 0.025
            let goalTopSpacing: CGFloat = side * 0.08
            let goalValueSpacing: CGFloat = side * 0.01
            
            let purposeFontSize = side * 0.06
            let goalLabelFontSize = side * 0.07
            let goalValueFontSize = side * 0.07
            
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 97/255, green: 113/255, blue: 82/255), // #617152
                        Color(red: 185/255, green: 215/255, blue: 157/255) // #B9D79D
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: spacing) {
                            Text(purpose)
                                .font(.custom("Roboto-Bold", size: purposeFontSize))
                                .minimumScaleFactor(0.8)
                                .foregroundColor(.white)
                                .lineLimit(nil)
                        Spacer()
                        if let goal {
                            VStack(alignment: .leading, spacing: goalValueSpacing) {
                                Text("ціль збору:")
                                    .font(.custom("Roboto-Bold", size: goalLabelFontSize))
                                    .minimumScaleFactor(0.8)
                                    .lineLimit(1)
                                    .foregroundColor(.white)
                                Text(goal)
                                    .font(.custom("Roboto-Bold", size: goalValueFontSize))
                                    .minimumScaleFactor(0.8)
                                    .lineLimit(1)
                                    .foregroundColor(.white)
                            }
                            .padding(.top, goalTopSpacing)
                        }
                    }
                    .padding(.leading, imageInset)
                    .padding(.vertical, imageInset)
                    .frame(width: leftWidth, alignment: .leading)
                                        
                    viewProvider()
                        .frame(width: side * 0.35, height: side)
                        .clipped()
                        .padding(.horizontal, imageInset)
                        
                }
                .frame(width: side, height: side)
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
                
                GreenGradientTemplateView(
                    purpose: "Для забезпечення 5 ОМБр", goal: "600.000", viewProvider: {
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
                
                GreenGradientTemplateView(
                    purpose: "Для забезпечення 5 ОМБр", goal: "600.000", viewProvider: {
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
                
                GreenGradientTemplateView(
                    purpose: "Для забезпечення 5 ОМБр", goal: "600.000", viewProvider: {
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
                
                GreenGradientTemplateView(
                    purpose: "Для забезпечення 5 ОМБр", goal: "600.000", viewProvider: {
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
                Text("Size: 1080/7 (154x154) - Most problematic")
                    .font(.caption)
                    .foregroundColor(.red)
                
                GreenGradientTemplateView(
                    purpose: "Для забезпечення 5 ОМБр", goal: "600.000", viewProvider: {
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
