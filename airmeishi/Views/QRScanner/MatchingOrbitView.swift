//
//  MatchingOrbitView.swift
//  airmeishi
//
//  Lightweight orbit animation used on the simplified Match screen
//

import SwiftUI

struct MatchingOrbitView: View {
    @State private var rotateOuter: Bool = false
    @State private var rotateMiddle: Bool = false
    @State private var rotateInner: Bool = false
    
    var body: some View {
        ZStack {
            // Concentric rings
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 2)
                .padding(4)
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 2)
                .padding(44)
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 2)
                .padding(84)
            
            // Center planet
            Circle()
                .fill(Color.white.opacity(0.25))
                .frame(width: 80, height: 80)
                .overlay(
                    Circle().stroke(Color.white.opacity(0.35), lineWidth: 1)
                )
            
            // Orbiting satellites
            orbit(radiusPadding: 4, size: 18)
                .rotationEffect(.degrees(rotateOuter ? 360 : 0))
                .animation(.linear(duration: 14).repeatForever(autoreverses: false), value: rotateOuter)
            orbit(radiusPadding: 44, size: 16)
                .rotationEffect(.degrees(rotateMiddle ? -360 : 0))
                .animation(.linear(duration: 10).repeatForever(autoreverses: false), value: rotateMiddle)
            orbit(radiusPadding: 84, size: 14)
                .rotationEffect(.degrees(rotateInner ? 360 : 0))
                .animation(.linear(duration: 7).repeatForever(autoreverses: false), value: rotateInner)
        }
        .onAppear {
            rotateOuter = true
            rotateMiddle = true
            rotateInner = true
        }
    }
    
    private func orbit(radiusPadding: CGFloat, size: CGFloat) -> some View {
        GeometryReader { proxy in
            let frame = proxy.size
            let minSide = min(frame.width, frame.height)
            let radius = (minSide / 2) - radiusPadding
            ZStack {
                satellite(size: size)
                    .offset(x: radius, y: 0)
                satellite(size: size)
                    .offset(x: 0, y: radius)
                satellite(size: size)
                    .offset(x: -radius * 0.9, y: -radius * 0.4)
                satellite(size: size)
                    .offset(x: radius * 0.4, y: -radius * 0.85)
            }
            .frame(width: frame.width, height: frame.height)
        }
    }
    
    private func satellite(size: CGFloat) -> some View {
        Circle()
            .fill(Color.white.opacity(0.8))
            .frame(width: size, height: size)
    }
}

#Preview {
    ZStack { Color.black.ignoresSafeArea(); MatchingOrbitView().frame(width: 300, height: 300) }
        .preferredColorScheme(.dark)
}


