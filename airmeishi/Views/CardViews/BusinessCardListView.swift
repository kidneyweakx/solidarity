//
//  BusinessCardListView.swift
//  airmeishi
//
//  Main view for displaying and managing business cards
//

import SwiftUI
import UIKit
import PassKit

struct BusinessCardListView: View {
    @EnvironmentObject private var proximityManager: ProximityManager
    @EnvironmentObject private var theme: ThemeManager
    @StateObject private var cardManager = CardManager.shared
    @State private var showingCreateCard = false
    @State private var showingOCRScanner = false
    @State private var featuredCard: BusinessCard?
    @State private var isFeatured = false
    @State private var isSharing = false
    @State private var showingAppearance = false
    @State private var showingReorder = false
    @State private var showingAddPass = false
    @State private var pendingPass: PKPass?
    @State private var alertMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                if cardManager.isLoading {
                    ProgressView("Loading cards...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if cardManager.businessCards.isEmpty {
                    EmptyWalletView(onCreate: { showingCreateCard = true }, onScan: { showingOCRScanner = true })
                } else {
                    WalletStackListView(cards: cardManager.businessCards,
                                        onEdit: { card in beginEdit(card) },
                                        onAddToWallet: { card in addToWallet(card) },
                                        onFocus: { card in
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                            featuredCard = card
                            isFeatured = true
                        }
                    })
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Create Card") { showingCreateCard = true }
                        Button("Scan Card") { showingOCRScanner = true }
                        Button("Appearance") { showingAppearance = true }
                        Button("Reorder Cards") { showingReorder = true }
                    } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingCreateCard) {
                BusinessCardFormView(businessCard: featuredCard) { saved in
                    // Keep focus on updated card
                    featuredCard = saved
                }
            }
            .sheet(isPresented: $showingOCRScanner) {
                OCRScannerView { extracted in
                    featuredCard = extracted
                    isFeatured = true
                    showingCreateCard = true
                }
            }
            .sheet(isPresented: $showingAppearance) {
                NavigationView { AppearanceSettingsView() }
                    .environmentObject(theme)
            }
            .sheet(isPresented: $showingAddPass) {
                if let pass = pendingPass {
                    AddPassesControllerView(pass: pass)
                }
            }
            .alert("Error", isPresented: .init(get: { alertMessage != nil }, set: { _ in alertMessage = nil })) {
                Button("OK", role: .cancel) { alertMessage = nil }
            } message: { Text(alertMessage ?? "") }
            .actionSheet(isPresented: $showingReorder) {
                ActionSheet(title: Text("Reorder"), message: Text("Move a card by selecting it as first, second, etc."), buttons: [
                    .default(Text("Move Selected to Top"), action: moveFeaturedToTop),
                    .cancel()
                ])
            }
        }
        .overlay(alignment: .top) { sharingBannerTop }
        .overlay { focusedOverlay }
    }
}

// MARK: - Sharing Helpers

private extension BusinessCardListView {
    func startSharing(_ card: BusinessCard) {
        proximityManager.stopAdvertising()
        proximityManager.startAdvertising(with: card, sharingLevel: .professional)
    }

    func beginEdit(_ card: BusinessCard) {
        featuredCard = card
        showingCreateCard = true
    }
    
    func addToWallet(_ card: BusinessCard) {
        let result = PassKitManager.shared.generatePass(for: card, sharingLevel: .professional)
        switch result {
        case .success(let passData):
            // Create PKPass and present add UI
            do {
                let pass = try PKPass(data: passData)
                pendingPass = pass
                showingAddPass = true
            } catch {
                alertMessage = "Failed to prepare Wallet pass: \(error.localizedDescription)"
            }
        case .failure(let err):
            alertMessage = err.localizedDescription
        }
    }
    
    @ViewBuilder
    var sharingBannerTop: some View {
        if proximityManager.isAdvertising {
            HStack(spacing: 8) {
                Image(systemName: "dot.radiowaves.left.and.right")
                    .foregroundColor(theme.cardAccent)
                Text("Sharing Nearby")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(.white)
                Spacer()
                Button("Stop") { proximityManager.stopAdvertising() }
                    .font(.footnote.weight(.semibold))
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(theme.cardAccent.opacity(0.25), lineWidth: 1)
                    )
                    .cardGlow(theme.cardAccent, enabled: theme.enableGlow)
            )
            .padding(.horizontal, 16)
            .padding(.top, 10)
        }
    }
    
    func cardDisplayName() -> String {
        proximityManager.getSharingStatus().currentCard?.name ?? "Card"
    }

    @ViewBuilder
    var focusedOverlay: some View {
        if isFeatured, let card = featuredCard {
            Color.black.opacity(0.45).ignoresSafeArea()
                .transition(.opacity)
                .onTapGesture {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                        isFeatured = false
                    }
                }
            FocusedCardView(card: card,
                             onEdit: { beginEdit(card) },
                             onDelete: { deleteCard(card) },
                             onClose: { withAnimation { isFeatured = false } })
                .padding(.horizontal, 20)
                .transition(.scale.combined(with: .opacity))
        }
    }
    
    func deleteCard(_ card: BusinessCard) {
        _ = cardManager.deleteCard(id: card.id)
        if featuredCard?.id == card.id { isFeatured = false }
    }
    
    func moveFeaturedToTop() {
        guard let id = featuredCard?.id else { return }
        let ordered = [id] + cardManager.businessCards.filter { $0.id != id }.map { $0.id }
        _ = cardManager.reorderCards(to: ordered)
    }
}

// MARK: - Deck Container

// Removed old wallet deck container and list variants for simplicity

// MARK: - Wallet Stack List (Apple Wallet-like)

private struct WalletStackListView: View {
    let cards: [BusinessCard]
    let onEdit: (BusinessCard) -> Void
    let onAddToWallet: (BusinessCard) -> Void
    let onFocus: (BusinessCard) -> Void
    
    private let cardHeight: CGFloat = 200
    private let overlap: CGFloat = 64
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            ZStack(alignment: .top) {
                ForEach(Array(cards.enumerated()), id: \.offset) { pair in
                    let index = pair.offset
                    let card = pair.element
                    WalletCardView(card: card, onEdit: { onEdit(card) }, onAddToWallet: { onAddToWallet(card) })
                        .frame(height: cardHeight)
                        .offset(y: CGFloat(index) * overlap)
                        .zIndex(Double(index))
                        .onTapGesture { onFocus(card) }
                }
            }
            .frame(height: CGFloat(max(cards.count - 1, 0)) * overlap + cardHeight)
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
    }
}

// A single large vertical wallet card with top-right category and edit/share control
private struct WalletCardView: View {
    let card: BusinessCard
    var onEdit: () -> Void
    var onAddToWallet: () -> Void
    
    @State private var isFlipped = false
    @EnvironmentObject private var theme: ThemeManager
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(perCardGradient(card: card))
                .shadow(color: Color.black.opacity(0.5), radius: 20, x: 0, y: 12)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(theme.cardAccent.opacity(0.35), lineWidth: 1)
                )
                .overlay(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(card.name)
                            .font(.title2).bold()
                            .foregroundColor(.black)
                        if let company = card.company { Text(company).foregroundColor(.black.opacity(0.7)) }
                        if let title = card.title { Text(title).font(.subheadline).foregroundColor(.black.opacity(0.6)) }
                    }
                    .padding(16)
                }
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                .animation(.spring(response: 0.5, dampingFraction: 0.85), value: isFlipped)
                .cardGlow(theme.cardAccent, enabled: theme.enableGlow)
            
            HStack(spacing: 8) {
                CategoryTag(text: category(for: card))
                Button(action: editTapped) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(8)
                        .background(theme.cardAccent.opacity(0.12))
                        .clipShape(Circle())
                }
                .padding(10)
                Button(action: addPassTapped) {
                    Image(systemName: "wallet.pass")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(8)
                        .background(theme.cardAccent.opacity(0.12))
                        .clipShape(Circle())
                }
                .padding(10)
            }
        }
    }
    
    private func editTapped() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        withAnimation { isFlipped = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation { isFlipped = false }
            onEdit()
        }
    }
    
    private func addPassTapped() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        onAddToWallet()
    }
    
    private func category(for card: BusinessCard) -> String {
        if let company = card.company, !company.isEmpty { return company }
        if let title = card.title, !title.isEmpty { return title }
        return "Card"
    }
    
    private func perCardGradient(card: BusinessCard) -> LinearGradient {
        // deterministic hue by UUID hash for variety
        let hash = card.id.uuidString.hashValue
        let hue = Double(abs(hash % 360)) / 360.0
        let base = Color(hue: hue, saturation: 0.55, brightness: 0.95)
        let light = Color.white
        return LinearGradient(colors: [light, base.opacity(0.22)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Components

private struct HorizontalCardView: View {
    let card: BusinessCard
    var onShare: () -> Void = {}
    @EnvironmentObject private var theme: ThemeManager
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(perCardGradient(card: card))
                .frame(height: 180)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(theme.cardAccent.opacity(0.35), lineWidth: 1)
                )
                .overlay(alignment: .topTrailing) { CategoryTag(text: category(for: card)).padding(6) }
                .cardGlow(theme.cardAccent, enabled: theme.enableGlow)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(card.name)
                    .font(.title2).bold()
                    .foregroundColor(.white)
                if let company = card.company { Text(company).foregroundColor(.white.opacity(0.8)) }
                if let title = card.title { Text(title).foregroundColor(.white.opacity(0.8)) }
            }
            .padding(16)
        }
        .onLongPressGesture(minimumDuration: 0.25) { onShare() }
    }
    private func category(for card: BusinessCard) -> String {
        if let company = card.company, !company.isEmpty { return company }
        if let title = card.title, !title.isEmpty { return title }
        return "Card"
    }
    
    private func perCardGradient(card: BusinessCard) -> LinearGradient {
        let hash = card.id.uuidString.hashValue
        let hue = Double(abs(hash % 360)) / 360.0
        let c1 = Color(hue: hue, saturation: 0.65, brightness: 0.85)
        let c2 = Color(hue: hue, saturation: 0.35, brightness: 0.25)
        return LinearGradient(colors: [c1, c2.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// Stacked deck of vertical cards with drag-to-feature interaction
private struct CardDeckView: View {
    let cards: [BusinessCard]
    @Binding var dragOffset: CGSize
    @Binding var isDragging: Bool
    let onFeature: (BusinessCard) -> Void
    @EnvironmentObject private var theme: ThemeManager
    
    var body: some View {
        ZStack(alignment: .top) {
            ForEach(Array(cards.enumerated()), id: \.offset) { pair in
                let index = pair.offset
                let card = pair.element
                let depth = cards.count - index - 1
                VerticalCardCell(card: card)
                    .overlay(alignment: .topTrailing) { CategoryTag(text: category(for: card)) }
                    .offset(y: CGFloat(depth) * 14)
                    .scaleEffect(1 - CGFloat(depth) * 0.03)
                    .opacity(depth <= 5 ? 1 : 0)
                    .zIndex(Double(index))
                    .allowsHitTesting(index == cards.count - 1) // only top card interactive
                    .offset(index == cards.count - 1 ? dragOffset : .zero)
                    .gesture(
                        index == cards.count - 1 ? DragGesture()
                            .onChanged { value in
                                isDragging = true
                                dragOffset = CGSize(width: value.translation.width * 0.2,
                                                    height: value.translation.height * 0.8)
                            }
                            .onEnded { value in
                                let threshold: CGFloat = -80
                                if value.translation.height < threshold {
                                    onFeature(card)
                                }
                                withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                                    isDragging = false
                                    dragOffset = .zero
                                }
                            }
                        : nil
                    )
                    .onTapGesture {
                        if index == cards.count - 1 { onFeature(card) }
                    }
            }
        }
        .frame(height: 240)
    }
    
    private func category(for card: BusinessCard) -> String {
        if let company = card.company, !company.isEmpty { return company }
        if let title = card.title, !title.isEmpty { return title }
        return "Card"
    }
}

// Simple right-top tag
private struct CategoryTag: View {
    let text: String
    @EnvironmentObject private var theme: ThemeManager
    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundColor(.white)
            .background(theme.cardAccent.opacity(0.25))
            .clipShape(Capsule())
            .padding(8)
    }
}

// Details under featured card
private struct CardDetailView: View {
    let card: BusinessCard
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let email = card.email { row(label: "Email", value: email) }
            if let phone = card.phone { row(label: "Phone", value: phone) }
            if let company = card.company { row(label: "Company", value: company) }
            if let title = card.title { row(label: "Title", value: title) }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
    }
    private func row(label: String, value: String) -> some View {
        HStack { Text(label).foregroundColor(.white.opacity(0.6)); Spacer(); Text(value).foregroundColor(.white) }
    }
}

// Deck list (compact) when not featured
private struct DeckListView: View {
    let cards: [BusinessCard]
    let onTap: (BusinessCard) -> Void
    var body: some View {
        VStack(spacing: 10) {
            ForEach(cards) { card in
                VerticalCardCell(card: card)
                    .overlay(alignment: .topTrailing) { CategoryTag(text: category(for: card)) }
                    .onTapGesture { onTap(card) }
            }
        }
    }
    private func category(for card: BusinessCard) -> String {
        if let company = card.company, !company.isEmpty { return company }
        if let title = card.title, !title.isEmpty { return title }
        return "Card"
    }
}
private struct VerticalCardCell: View {
    let card: BusinessCard
    @EnvironmentObject private var theme: ThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(theme.cardAccent.opacity(0.16))
                .frame(width: 56, height: 84)
                .overlay(
                    Text(card.name.prefix(1))
                        .font(.title2).bold()
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 6) {
                Text(card.name).font(.headline).foregroundColor(.white)
                if let company = card.company { Text(company).font(.subheadline).foregroundColor(.white.opacity(0.8)) }
                if let title = card.title { Text(title).font(.caption).foregroundColor(.white.opacity(0.7)) }
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundColor(.white.opacity(0.5))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(theme.cardAccent.opacity(0.18), lineWidth: 1)
                )
        )
        .cardGlow(theme.cardAccent, enabled: theme.enableGlow)
        // context menu could be wired via callbacks if needed
    }
}

private struct EmptyWalletView: View {
    let onCreate: () -> Void
    let onScan: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.rectangle").font(.system(size: 64)).foregroundColor(.white.opacity(0.4))
            Text("Business Card Not Found").font(.title2).bold().foregroundColor(.white)
            Text("Add a card or scan to get started").foregroundColor(.white.opacity(0.7))
            HStack(spacing: 12) {
                Button("Add Card", action: onCreate).buttonStyle(.borderedProminent)
                Button("Scan Card", action: onScan).buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview { BusinessCardListView() }