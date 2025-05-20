import SwiftUI

struct GreenGradientTemplateView: View {
    let purpose: String
    let goal: String
    
    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            let leftWidth = side * 0.5
            let rightWidth = side * 0.4
            let imageInset: CGFloat = side * 0.08
            let spacing: CGFloat = side * 0.025
            let goalTopSpacing: CGFloat = side * 0.08
            let goalValueSpacing: CGFloat = side * 0.01
            
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
                                .font(.body)
                                .minimumScaleFactor(0.2)
                                .foregroundColor(.white)
                                .lineLimit(nil)
                        Spacer()
                        VStack(alignment: .leading, spacing: goalValueSpacing) {
                            Text("ціль збору:")
                                .font(.custom("Roboto-Bold", size: 28)
                                )
                                .lineLimit(1)
                                .foregroundColor(.white)
                            Text(goal)
                                .font(.headline)
                                .font(.custom("Roboto-Bold", size: 38)
                                )
                                .minimumScaleFactor(0.35)
                                .lineLimit(1)
                                .foregroundColor(.white)
                        }
                        .padding(.top, goalTopSpacing)
                    }
                    .padding(.leading, imageInset)
                    .padding(.vertical, imageInset)
                    .frame(width: leftWidth, alignment: .leading)
                                        
                    Rectangle()
                        .fill(Color.white)
                        .padding(.horizontal, imageInset)
                        
                }
                .frame(width: side, height: side)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

#Preview {
    GreenGradientTemplateView(
        purpose: "Для забезпечення 5 ОМБр", goal: "600.000"
    )
    .frame(width: 1080/3, height: 1350/3)
}
