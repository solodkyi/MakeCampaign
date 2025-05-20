import SwiftUI

struct SilverBlueTemplateView: View {
    let goal: String
    let description: String
    
    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            let horizontalPadding = side * 0.05
            let verticalPadding = side * 0.06
            let bottomTextSpacing = side * 0.02
            
            ZStack {
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(hex: "#95C5E5"), location: 0),
                        .init(color: Color(hex: "#88B4D1"), location: 0.235),
                        .init(color: Color(hex: "#8ABFE2"), location: 0.559),
                        .init(color: Color(hex: "#386786"), location: 1)
                    ]),
                    startPoint: UnitPoint(x: 0.016, y: 1),
                    endPoint: UnitPoint(x: 0.94, y: 1)
                )
                .ignoresSafeArea()
                
                VStack(alignment: .trailing) {
                    HStack {
                        Spacer()
                        Rectangle()
                            .fill(Color.white)
                            .padding(.top, verticalPadding)
                    }
                    .padding(.leading, 3*horizontalPadding)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: bottomTextSpacing) {
                        Text("Збір на \(goal)")
                            .font(.custom("Roboto-Bold", size: 44))
                            .foregroundColor(.white)
                            .minimumScaleFactor(0.2)

                        Text(description)
                            .multilineTextAlignment(.leading)
                            .font(.custom("Roboto-Bold", size: 28)
                            )
                            .minimumScaleFactor(0.2)
                            .foregroundColor(.white)
                            .lineLimit(nil)
                    }
                    .padding(.top, verticalPadding/2)
                    .padding(.bottom, verticalPadding * 1.3)
                    .padding(.leading, 3*horizontalPadding)
                    .padding(.trailing, horizontalPadding)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

#Preview {
    SilverBlueTemplateView(
        goal: "000.000",
        description: "текст текст тексттекст текст тексттекст текст "
    )
    .frame(width: 1080/3, height: 1350/3)
}
