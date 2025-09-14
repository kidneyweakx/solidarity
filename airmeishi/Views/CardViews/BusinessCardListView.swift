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
                    WalletStackListView(cards: cardManager.businessCards,
                                        onEdit: { card in beginEdit(card) },
                                        onAddToWallet: { card in addToWallet(card) },
                                        onFocus: { card in
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                            featuredCard = card
                            isFeatured = true
                        }
                    },
                                        onDrag: { card, offset in
                        draggedCard = card
                        dragOffset = offset
                    },
                                        onDragEnd: { card in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            draggedCard = nil
                            dragOffset = .zero
                        }
                    })
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
}

// MARK: - Wallet Stack List (Apple Wallet-like)

private struct WalletStackListView: View {
    let cards: [BusinessCard]
    let onEdit: (BusinessCard) -> Void
    let onAddToWallet: (BusinessCard) -> Void
    let onFocus: (BusinessCard) -> Void
    let onDrag: (BusinessCard, CGSize) -> Void
    let onDragEnd: (BusinessCard) -> Void
    
    private let cardHeight: CGFloat = 220
    private let overlap: CGFloat = 72
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(Array(cards.enumerated()), id: \.offset) { pair in
                    let index = pair.offset
                    let card = pair.element
                    WalletCardView(card: card, onEdit: { onEdit(card) }, onAddToWallet: { onAddToWallet(card) })
                        .frame(height: cardHeight)
                        .offset(y: CGFloat(index) * overlap)
                        .zIndex(Double(cards.count - index))
                        .onTapGesture { onFocus(card) }
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    onDrag(card, value.translation)
                                }
                                .onEnded { _ in
                                    onDragEnd(card)
                                }
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, index == 0 ? 16 : -overlap)
                }
            }
            .padding(.bottom, 40)
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
                .overlay {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(card.name)
                                .font(.title2.weight(.bold))
                                .foregroundColor(.black)
                            if let company = card.company { Text(company).foregroundColor(.black.opacity(0.75)) }
                            if let title = card.title { Text(title).font(.subheadline).foregroundColor(.black.opacity(0.65)) }
                            Spacer()
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
                        .padding(16)
                        Spacer()
                        if let animal = card.animal {
                            ImageProvider.animalImage(for: animal)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 96, height: 96)
                                .opacity(0.95)
                                .padding(.trailing, 14)
                                .padding(.top, 8)
                        }
                    }
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
                colors = [Color(hex: 0xFFF8E1), Color(hex: 0xFFD54F).opacity(0.35)]
            case .horse:
                colors = [Color(hex: 0xE8EAF6), Color(hex: 0x5C6BC0).opacity(0.35)]
            case .pig:
                colors = [Color(hex: 0xFCE4EC), Color(hex: 0xF06292).opacity(0.35)]
            case .sheep:
                colors = [Color(hex: 0xE8F5E9), Color(hex: 0x66BB6A).opacity(0.35)]
            case .dove:
                colors = [Color(hex: 0xE0F7FA), Color(hex: 0x26C6DA).opacity(0.35)]
            }
            return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        // Fallback deterministic hue by UUID
        let hash = card.id.uuidString.hashValue
        let hue = Double(abs(hash % 360)) / 360.0
        let base = Color(hue: hue, saturation: 0.55, brightness: 0.95)
        let light = Color.white
        return LinearGradient(colors: [light, base.opacity(0.22)], startPoint: .topLeading, endPoint: .bottomTrailing)
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
                Button("Scan Card", action: onScan).buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview { BusinessCardListView() }