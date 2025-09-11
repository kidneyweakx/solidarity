//
//  FocusedCardView.swift
//  airmeishi
//
//  Centered single-card focus overlay with edit and swipe-to-delete
//

import SwiftUI

struct FocusedCardView: View {
    let card: BusinessCard
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onClose: () -> Void
    
    @GestureState private var dragOffset: CGSize = .zero
    @EnvironmentObject private var theme: ThemeManager
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(gradient(card))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(theme.cardAccent.opacity(0.35), lineWidth: 1)
                    )
                    .cardGlow(theme.cardAccent, enabled: theme.enableGlow)
                    .frame(height: 240)
                    .overlay { cardContent() }
                    .offset(x: dragOffset.width)
                    .gesture(
                        DragGesture()
                            .updating($dragOffset) { value, state, _ in
                                state = value.translation
                            }
                            .onEnded { value in
                                if value.translation.width < -80 { onDelete() }
                                if value.translation.width > 80 { onEdit() }
                            }
                    )
                Button(action: onEdit) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(8)
                        .background(theme.cardAccent.opacity(0.15))
                        .clipShape(Circle())
                }
                .padding(10)
            }
            HStack(spacing: 12) {
                Button("Close") { onClose() }
                    .buttonStyle(.bordered)
                Button("Delete", role: .destructive) { onDelete() }
                    .buttonStyle(.borderedProminent)
            }
        }
    }
    
    @ViewBuilder
    private func cardContent() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(card.name).font(.title2).bold().foregroundColor(.black)
            if let company = card.company { Text(company).foregroundColor(.black.opacity(0.7)) }
            if let title = card.title { Text(title).font(.subheadline).foregroundColor(.black.opacity(0.6)) }
            Spacer()
            HStack {
                if let email = card.email { label("envelope", email) }
                Spacer()
                if let phone = card.phone { label("phone", phone) }
            }
        }
        .padding(18)
    }
    
    private func label(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).foregroundColor(.black.opacity(0.7))
            Text(text).font(.caption).foregroundColor(.black.opacity(0.8))
        }
        .padding(8)
        .background(Color.white.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
    
    private func gradient(_ card: BusinessCard) -> LinearGradient {
        let hash = card.id.uuidString.hashValue
        let hue = Double(abs(hash % 360)) / 360.0
        let c1 = Color(hue: hue, saturation: 0.7, brightness: 1.0)
        let c2 = Color.white
        return LinearGradient(colors: [c2, c1.opacity(0.24)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}


