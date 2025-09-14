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
    @State private var showingAddPass = false
    @State private var pendingPass: PKPass?
    @State private var alertMessage: String?
    @State private var draggedCard: BusinessCard?
    @State private var dragOffset: CGSize = .zero
    @State private var deckOrder: [UUID] = []
    @State private var rotationAngles: [UUID: Double] = [:]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                if cardManager.isLoading {
                    ProgressView("Loading cards...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if cardManager.businessCards.isEmpty {
                    EmptyWalletView(onCreate: { featuredCard = nil; showingCreateCard = true }, onScan: { showingOCRScanner = true })
                } else {
                    makeStack()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Create Card") { featuredCard = nil; showingCreateCard = true }
                        Button("Scan Card") { showingOCRScanner = true }
                        Button("Appearance") { showingAppearance = true }
                    } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingCreateCard) {
                // If featuredCard is nil, we are creating. Otherwise we are editing the selected card.
                BusinessCardFormView(businessCard: featuredCard, forceCreate: featuredCard == nil) { saved in
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
        }
        .overlay(alignment: .top) { sharingBannerTop }
        .overlay { focusedOverlay }
        .onAppear { initializeDeckOrder() }
        .onChange(of: cardManager.businessCards) { _, _ in synchronizeDeckWithData() }
    }
}

// MARK: - Sharing Helpers

private extension BusinessCardListView {
    @ViewBuilder
    func makeStack() -> some View {
        WalletStackListView(
            cards: orderedCards,
            onEdit: beginEdit,
            onAddToWallet: addToWallet,
            onFocus: handleFocus,
            onDrag: handleDragChange,
            onDragEnd: handleDragEnd,
            onLongPress: shuffleDeck,
            rotationFor: rotationFor
        )
    }
    var orderedCards: [BusinessCard] {
        let idToCard: [UUID: BusinessCard] = Dictionary(uniqueKeysWithValues: cardManager.businessCards.map { ($0.id, $0) })
        var result: [BusinessCard] = []
        for id in deckOrder {
            if let c = idToCard[id] { result.append(c) }
        }
        // Append any new cards not tracked yet
        let remaining = cardManager.businessCards.filter { !deckOrder.contains($0.id) }
        result.append(contentsOf: remaining)
        return result
    }

    func initializeDeckOrder() {
        deckOrder = cardManager.businessCards.map { $0.id }
    }

    func synchronizeDeckWithData() {
        // Keep deck order stable; append new ids at the end, remove missing ones
        let currentIds = Set(cardManager.businessCards.map { $0.id })
        deckOrder = deckOrder.filter { currentIds.contains($0) }
        for id in cardManager.businessCards.map({ $0.id }) where !deckOrder.contains(id) {
            deckOrder.append(id)
        }
    }

    func shuffleDeck() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
            deckOrder.shuffle()
            var angles: [UUID: Double] = [:]
            for id in deckOrder { angles[id] = Double(Int.random(in: -8...8)) }
            rotationAngles = angles
        }
    }
    func startSharing(_ card: BusinessCard) {
        proximityManager.stopAdvertising()
        proximityManager.startAdvertising(with: card, sharingLevel: .professional)
    }
    func handleFocus(_ card: BusinessCard) {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            featuredCard = card
            isFeatured = true
        }
    }

    func handleDragChange(_ card: BusinessCard, _ offset: CGSize) {
        draggedCard = card
        dragOffset = offset
    }

    func handleDragEnd(_ card: BusinessCard) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            draggedCard = nil
            dragOffset = .zero
        }
    }

    func rotationFor(_ id: UUID) -> Double { rotationAngles[id] ?? 0 }


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
            Color.black.opacity(0.75).ignoresSafeArea()
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
}

// MARK: - Wallet Stack List (Apple Wallet-like)

private struct WalletStackListView: View {
    let cards: [BusinessCard]
    let onEdit: (BusinessCard) -> Void
    let onAddToWallet: (BusinessCard) -> Void
    let onFocus: (BusinessCard) -> Void
    let onDrag: (BusinessCard, CGSize) -> Void
    let onDragEnd: (BusinessCard) -> Void
    let onLongPress: () -> Void
    let rotationFor: (UUID) -> Double
    
    private let cardHeight: CGFloat = 220
    private let overlap: CGFloat = 64
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(Array(cards.enumerated()), id: \.offset) { pair in
                    let index = pair.offset
                    let card = pair.element
                    WalletCardView(card: card, onEdit: { onEdit(card) }, onAddToWallet: { onAddToWallet(card) })
                        .frame(height: cardHeight)
                        .offset(y: CGFloat(index) * overlap)
                        .rotationEffect(.degrees(rotationFor(card.id)))
                        .offset(x: CGFloat(rotationFor(card.id)) * 1.2)
                        .scaleEffect(1 - CGFloat(min(index, 4)) * 0.02)
                        .zIndex(Double(index))
                        .onTapGesture { onFocus(card) }
                        .simultaneousGesture(
                            DragGesture()
                                .onChanged { value in
                                    let translation = value.translation
                                    if abs(translation.width) > abs(translation.height) {
                                        onDrag(card, translation)
                                    }
                                }
                                .onEnded { value in
                                    let translation = value.translation
                                    if abs(translation.width) > abs(translation.height) {
                                        onDragEnd(card)
                                    }
                                }
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, index == 0 ? 16 : -overlap)
                        .padding(.bottom, -overlap)
                }
            }
            .gesture(LongPressGesture(minimumDuration: 0.6).onEnded { _ in onLongPress() })
            .padding(.bottom, CGFloat(max(0, cards.count - 1)) * overlap + 160)
        }
        .scrollDisabled(false)
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
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(perCardGradient(card: card))
                .shadow(color: Color.black.opacity(0.45), radius: 24, x: 0, y: 14)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(theme.cardAccent.opacity(0.35), lineWidth: 1)
                )
                // Gloss highlight for premium look
                .overlay(alignment: .topLeading) {
                    LinearGradient(
                        colors: [Color.white.opacity(0.45), Color.white.opacity(0.12), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .opacity(0.65)
                }
                .overlay {
                    HStack(alignment: .center, spacing: 14) {
                        if let animal = card.animal {
                            ImageProvider.animalImage(for: animal)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 84, height: 84)
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                                )
                                .padding(.leading, 18)
                        } else {
                            Spacer().frame(width: 18)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text(card.name)
                                .font(.headline.weight(.semibold))
                                .foregroundColor(.black)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            if let company = card.company { Text(company).font(.subheadline).foregroundColor(.black.opacity(0.75)) }
                            if let title = card.title { Text(title).font(.footnote).foregroundColor(.black.opacity(0.65)) }
                            HStack(spacing: 6) {
                                ForEach(card.skills.prefix(3)) { skill in
                                    Text(skill.name)
                                        .font(.caption2.weight(.semibold))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.white.opacity(0.18))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        // Theme by animal when present
        if let animal = card.animal {
            let colors: [Color]
            switch animal {
            case .dog:
                colors = [Color(hex: 0xFFF8E1), Color(hex: 0xFFD54F)]
            case .horse:
                colors = [Color(hex: 0xE8EAF6), Color(hex: 0x5C6BC0)]
            case .pig:
                colors = [Color(hex: 0xFCE4EC), Color(hex: 0xF06292)]
            case .sheep:
                colors = [Color(hex: 0xE8F5E9), Color(hex: 0x66BB6A)]
            case .dove:
                colors = [Color(hex: 0xE0F7FA), Color(hex: 0x26C6DA)]
            }
            return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        // Fallback deterministic hue by UUID
        let hash = card.id.uuidString.hashValue
        let hue = Double(abs(hash % 360)) / 360.0
        let base = Color(hue: hue, saturation: 0.55, brightness: 0.95)
        let light = Color.white
        return LinearGradient(colors: [light, base], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Components

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
                Button("Scan Card", action: onScan).buttonStyle(.bordered).foregroundColor(.gray)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview { BusinessCardListView() }