//
//  RedBlackGradientTemplateView.swift
//  MakeCampaign
//
//  Created by Andrii Solodkyi on 5/20/25.
//

import SwiftUI

struct RedBlackGradientTemplateView: View {
    let goal: String?
    let purpose: String
    var viewProvider: () -> AnyView
    
    init(purpose: String, goal: String?, viewProvider: @escaping () -> some View = { Color.clear }) {
        self.purpose = purpose
        self.goal = goal
        self.viewProvider = { AnyView(viewProvider()) }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            let verticalPadding = side * 0.06
            let horizontalPadding = side * 0.05
            let imageWidth = side * 432 / 1080
            let imageHeight = side * 728 / 1080
            
            let purposeFontSize = side * 0.06
            let goalFontSize = side * 0.08
            
            ZStack {
                RadialGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(hex: "#E73535"), location: 0),
                        .init(color: Color(hex: "#0C0C0C"), location: 1)
                    ]),
                    center: UnitPoint(x: 0.89, y: 0.23),
                    startRadius: 0,
                    endRadius: side * 1.5
                )
                .ignoresSafeArea()
                
                HStack(spacing: 0) {
                    VStack(alignment: .leading) {
                        Text(purpose)
                            .multilineTextAlignment(.leading)
                            .font(.custom("Roboto-Bold", size: purposeFontSize))
                            .foregroundColor(.white)
                            .minimumScaleFactor(0.8)
                            .lineLimit(nil)
                            .padding(horizontalPadding)
                    }
  
                        VStack(alignment: .trailing) {
                            viewProvider()
                                .frame(width: imageWidth, height: imageHeight)
                                .clipped()
                            Spacer()
                            
                            if let goal {
                                VStack(alignment: .trailing, spacing: 5) {
                                    Text("ціль збору:")
                                        .font(.custom("Roboto-Bold", size: goalFontSize))
                                        .lineLimit(1)
                                        .foregroundColor(.white)
                                        .minimumScaleFactor(0.8)
                                    
                                    Text(goal)
                                        .font(.custom("Roboto-Bold", size: goalFontSize))
                                        .lineLimit(1)
                                        .foregroundColor(.white)
                                        .minimumScaleFactor(0.8)
                                }
                                .padding(.bottom, verticalPadding)
                            }
                    }
                        .padding(.trailing, horizontalPadding*2)
                }
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
                
                RedBlackGradientTemplateView(
                    purpose: "текст текст текст текст",
                    goal: "000.000"
                ) {
                    if let imageData = Campaign.mock1.image?.raw, let uiImage = UIImage(data: imageData) {
                        let initialOffset = Campaign.mock1.image?.offset ?? .zero
                        let initialScale = Campaign.mock1.image?.scale ?? 1.0
                        
                        return AnyView(
                            ImageTransformPreview(
                                image: uiImage,
                                initialOffset: initialOffset,
                                initialScale: initialScale
                            )
                        )
                    } else {
                        return AnyView(Rectangle().fill(Color.red))
                    }
                }
                .frame(width: 1080/3, height: 1080/3)
            }
            
            VStack(spacing: 10) {
                Text("Size: 1080/4 (270x270)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                RedBlackGradientTemplateView(
                    purpose: "текст текст текст текст",
                    goal: "000.000"
                ) {
                    if let imageData = Campaign.mock1.image?.raw, let uiImage = UIImage(data: imageData) {
                        let initialOffset = Campaign.mock1.image?.offset ?? .zero
                        let initialScale = Campaign.mock1.image?.scale ?? 1.0
                        
                        return AnyView(
                            ImageTransformPreview(
                                image: uiImage,
                                initialOffset: initialOffset,
                                initialScale: initialScale
                            )
                        )
                    } else {
                        return AnyView(Rectangle().fill(Color.red))
                    }
                }
                .frame(width: 1080/4, height: 1080/4)
            }
            
            VStack(spacing: 10) {
                Text("Size: 1080/5 (216x216)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                RedBlackGradientTemplateView(
                    purpose: "текст текст текст текст",
                    goal: "000.000"
                ) {
                    if let imageData = Campaign.mock1.image?.raw, let uiImage = UIImage(data: imageData) {
                        let initialOffset = Campaign.mock1.image?.offset ?? .zero
                        let initialScale = Campaign.mock1.image?.scale ?? 1.0
                        
                        return AnyView(
                            ImageTransformPreview(
                                image: uiImage,
                                initialOffset: initialOffset,
                                initialScale: initialScale
                            )
                        )
                    } else {
                        return AnyView(Rectangle().fill(Color.red))
                    }
                }
                .frame(width: 1080/5, height: 1080/5)
            }
            
            VStack(spacing: 10) {
                Text("Size: 1080/6 (180x180)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                RedBlackGradientTemplateView(
                    purpose: "текст текст текст текст",
                    goal: "000.000"
                ) {
                    if let imageData = Campaign.mock1.image?.raw, let uiImage = UIImage(data: imageData) {
                        let initialOffset = Campaign.mock1.image?.offset ?? .zero
                        let initialScale = Campaign.mock1.image?.scale ?? 1.0
                        
                        return AnyView(
                            ImageTransformPreview(
                                image: uiImage,
                                initialOffset: initialOffset,
                                initialScale: initialScale
                            )
                        )
                    } else {
                        return AnyView(Rectangle().fill(Color.red))
                    }
                }
                .frame(width: 1080/6, height: 1080/6)
            }
            
            VStack(spacing: 10) {
                Text("Size: 1080/7 (154x154)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                RedBlackGradientTemplateView(
                    purpose: "текст текст текст текст",
                    goal: "000.000"
                ) {
                    if let imageData = Campaign.mock1.image?.raw, let uiImage = UIImage(data: imageData) {
                        let initialOffset = Campaign.mock1.image?.offset ?? .zero
                        let initialScale = Campaign.mock1.image?.scale ?? 1.0
                        
                        return AnyView(
                            ImageTransformPreview(
                                image: uiImage,
                                initialOffset: initialOffset,
                                initialScale: initialScale
                            )
                        )
                    } else {
                        return AnyView(Rectangle().fill(Color.red))
                    }
                }
                .frame(width: 1080/7, height: 1080/7)
            }
        }
        .padding()
    }
}

struct ImageTransformPreview: View {
    let image: UIImage
    
    @State private var offset: CGSize
    @State private var scale: CGFloat
    
    init(image: UIImage, initialOffset: CGSize, initialScale: CGFloat) {
        self.image = image
        _offset = State(initialValue: initialOffset)
        _scale = State(initialValue: initialScale)
    }
    
    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .scaleEffect(scale)
            .offset(offset)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        offset = gesture.translation
                    }
            )
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        scale = value
                    }
                    .onEnded { value in
                        scale = max(1.0, value)
                    }
            )
    }
}

