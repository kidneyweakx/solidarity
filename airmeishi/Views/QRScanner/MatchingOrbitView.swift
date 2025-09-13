//
//  MatchingOrbitView.swift
//  airmeishi
//
//  Lightweight orbit animation used on the simplified Match screen
//

import SwiftUI

struct MatchingOrbitView: View {
    @StateObject private var proximityManager = ProximityManager.shared
    @StateObject private var cardManager = CardManager.shared
    @State private var rotateOuter: Bool = false
    @State private var rotateMiddle: Bool = false
    @State private var rotateInner: Bool = false
    @State private var showNearbySheet: Bool = false
    @State private var showPeerCardSheet: Bool = false
    @State private var showShareSheet: Bool = false
    
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
            
            // Center planet (tappable)
            Button(action: { showNearbySheet = true }) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.25))
                        .frame(width: 96, height: 96)
                        .overlay(
                            Circle().stroke(Color.white.opacity(0.35), lineWidth: 1)
                        )
                    VStack(spacing: 2) {
                        Text("Nearby")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                        Text("\(proximityManager.nearbyPeers.count)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
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
        // Top overlay removed; center planet handles interactions
        .onAppear {
            rotateOuter = true
            rotateMiddle = true
            rotateInner = true
        }
        .overlay(
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { showShareSheet = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: proximityManager.getSharingStatus().isAdvertising ? "antenna.radiowaves.left.and.right" : "paperplane")
                            Text(proximityManager.getSharingStatus().isAdvertising ? "Sharing" : "Share")
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.2))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                    }
                    .padding()
                }
            }
        )
        .sheet(isPresented: $showNearbySheet) {
            NearbyPeersSheet(
                peers: proximityManager.nearbyPeers,
                connectedCount: proximityManager.getSharingStatus().connectedPeersCount,
                onViewLatestCard: {
                    if proximityManager.receivedCards.last != nil {
                        showPeerCardSheet = true
                    }
                }
            )
        }
        .sheet(isPresented: $showPeerCardSheet) {
            if let card = proximityManager.receivedCards.last {
                ReceivedCardView(card: card)
            } else {
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                    Text("Waiting for peer's card...")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                .padding()
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareCardPickerSheet(
                cards: cardManager.businessCards,
                onStart: { card, level in
                    proximityManager.startAdvertising(with: card, sharingLevel: level)
                },
                onStop: {
                    proximityManager.stopAdvertising()
                },
                isAdvertising: proximityManager.getSharingStatus().isAdvertising
            )
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

// MARK: - Nearby Peers Sheet

private struct NearbyPeersSheet: View {
    let peers: [ProximityPeer]
    let connectedCount: Int
    let onViewLatestCard: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var isLightningAnimating = false
    @State private var searchText = ""
    @State private var selectedPeer: ProximityPeer?
    @State private var showingPeerDetail = false
    
    var filteredPeers: [ProximityPeer] {
        if searchText.isEmpty {
            return peers
        } else {
            return peers.filter { peer in
                peer.cardName?.localizedCaseInsensitiveContains(searchText) == true ||
                peer.cardTitle?.localizedCaseInsensitiveContains(searchText) == true ||
                peer.cardCompany?.localizedCaseInsensitiveContains(searchText) == true ||
                peer.name.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dark gradient background with lightning effect
                LinearGradient(
                    colors: [
                        Color.black,
                        Color.blue.opacity(0.1),
                        Color.purple.opacity(0.05),
                        Color.black
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
            VStack(spacing: 0) {
                    // Lightning header
                    lightningHeader
                    
                    // Search bar
                    searchBar
                    
                    // Content
                    if filteredPeers.isEmpty && !searchText.isEmpty {
                        emptySearchState
                    } else if filteredPeers.isEmpty {
                        emptyState
                    } else {
                        peersGrid
                    }
                    
                    // Lightning action button
                    if connectedCount > 0 {
                        lightningActionButton
                    }
                }
            }
            .navigationTitle("Lightning Peers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white)
                }
            }
            .onAppear {
                isLightningAnimating = true
            }
            .sheet(isPresented: $showingPeerDetail) {
                if let peer = selectedPeer {
                    PeerDetailSheet(peer: peer)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Lightning Header
    
    private var lightningHeader: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(.yellow)
                    .font(.title)
                    .scaleEffect(isLightningAnimating ? 1.3 : 1.0)
                    .animation(
                        .easeInOut(duration: 0.5).repeatForever(autoreverses: true),
                        value: isLightningAnimating
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Lightning Peers")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("\(peers.count) nearby connections")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Live connection indicator
                HStack(spacing: 8) {
                    Circle()
                        .fill(connectedCount > 0 ? .green : .orange)
                        .frame(width: 8, height: 8)
                        .scaleEffect(isLightningAnimating ? 1.3 : 1.0)
                        .animation(
                            .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                            value: isLightningAnimating
                        )
                    
                    Text("\(connectedCount) connected")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.yellow)
            
            TextField("Search peers...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .foregroundColor(.white)
            
            if !searchText.isEmpty {
                Button("Clear") {
                    searchText = ""
                }
                .font(.caption)
                .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
    
    // MARK: - Peers Grid
    
    private var peersGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ForEach(filteredPeers) { peer in
                    LightningPeerCard(
                        peer: peer,
                        isLightningAnimating: isLightningAnimating
                    ) {
                        selectedPeer = peer
                        showingPeerDetail = true
                    }
                }
            }
            .padding()
            .padding(.bottom, connectedCount > 0 ? 100 : 20)
        }
    }
    
    // MARK: - Empty States
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 2)
                    .frame(width: 120, height: 120)
                    .scaleEffect(isLightningAnimating ? 1.1 : 1.0)
                    .animation(
                        .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                        value: isLightningAnimating
                    )
                
                Image(systemName: "person.2.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
            }
            
            VStack(spacing: 8) {
                Text("No Lightning Peers Yet")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Start matching to discover nearby professionals with lightning-fast connections")
                            .font(.body)
                    .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptySearchState: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("No Results")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("No peers match your search")
                    .font(.body)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Lightning Action Button
    
    private var lightningActionButton: some View {
        VStack {
            Spacer()
            
            Button(action: onViewLatestCard) {
                HStack(spacing: 12) {
                    Image(systemName: "bolt.fill")
                        .font(.title2)
                        .scaleEffect(isLightningAnimating ? 1.3 : 1.0)
                        .animation(
                            .easeInOut(duration: 0.3).repeatForever(autoreverses: true),
                            value: isLightningAnimating
                        )
                    
                    Text("View Latest Lightning Card")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [.yellow, .orange, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .yellow.opacity(0.5), radius: 10, x: 0, y: 0)
                )
            }
                            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }
}

// MARK: - Lightning Peer Card

struct LightningPeerCard: View {
    let peer: ProximityPeer
    let isLightningAnimating: Bool
    let onTap: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Header with avatar and status
                HStack {
                    // Avatar with lightning border
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [statusColor, statusColor.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)
                        
                        Text(peerAvatarInitials)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        // Lightning ring for connected peers
                        if peer.status == .connected {
                            Circle()
                                .stroke(Color.yellow, lineWidth: 2)
                                .frame(width: 56, height: 56)
                                .scaleEffect(isLightningAnimating ? 1.1 : 1.0)
                                .animation(
                                    .easeInOut(duration: 0.5).repeatForever(autoreverses: true),
                                    value: isLightningAnimating
                                )
                        }
                    }
                    
                    Spacer()
                    
                    // Status and verification
                    VStack(alignment: .trailing, spacing: 4) {
                        // Status indicator
                        HStack(spacing: 4) {
                            Circle()
                                .fill(statusColor)
                                .frame(width: 8, height: 8)
                                .scaleEffect(isLightningAnimating ? 1.2 : 1.0)
                                .animation(
                                    .easeInOut(duration: 0.5).repeatForever(autoreverses: true),
                                    value: isLightningAnimating
                                )
                            
                            Text(peer.status.rawValue)
                                .font(.caption2)
                                .foregroundColor(.white)
                        }
                        
                        // Verification badge
                        if let verification = peer.verification {
                            HStack(spacing: 2) {
                                Image(systemName: verification.systemImageName)
                                    .font(.caption2)
                                    .foregroundColor(verificationColor)
                                Text(verification.displayName)
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        } else if peer.discoveryInfo["zk"] == "1" {
                            HStack(spacing: 2) {
                                Image(systemName: "shield.checkerboard")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                                Text("ZK Ready")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                
                // Peer info
                            VStack(alignment: .leading, spacing: 4) {
                    Text(peer.cardName ?? peer.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    if let title = peer.cardTitle {
                        Text(title)
                            .font(.caption)
                            .foregroundColor(.yellow)
                            .lineLimit(1)
                    }
                    
                    if let company = peer.cardCompany {
                        Text(company)
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Lightning bolt indicator
                HStack {
                    Spacer()
                    Image(systemName: "bolt.fill")
                        .foregroundColor(isLightningAnimating ? .yellow : .gray)
                        .font(.caption)
                        .scaleEffect(isLightningAnimating ? 1.2 : 1.0)
                        .animation(
                            .easeInOut(duration: 0.3).repeatForever(autoreverses: true),
                            value: isLightningAnimating
                        )
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isLightningAnimating ? Color.yellow.opacity(0.3) : Color.white.opacity(0.1),
                                lineWidth: 1
                            )
                    )
            )
            .scaleEffect(isHovering ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovering = hovering
        }
    }
    
    private var peerAvatarInitials: String {
        let name = peer.cardName ?? peer.name
        let components = name.components(separatedBy: " ")
        let initials = components.compactMap { $0.first }.map { String($0) }
        return initials.prefix(2).joined().uppercased()
    }
    
    private var statusColor: Color {
        switch peer.status {
        case .connected: return .green
        case .connecting: return .orange
        case .disconnected: return .gray
        }
    }
    
    private var verificationColor: Color {
        if let verification = peer.verification {
            switch verification {
            case .verified: return .green
            case .pending: return .orange
            case .unverified: return .blue
            case .failed: return .red
            }
        }
        return .blue
    }
}

// MARK: - Peer Detail Sheet

struct PeerDetailSheet: View {
    let peer: ProximityPeer
    @Environment(\.dismiss) private var dismiss
    @State private var isLightningAnimating = false
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color.black, Color.blue.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Lightning header
                        HStack {
                            Image(systemName: "bolt.fill")
                                .foregroundColor(.yellow)
                                .font(.title)
                                .scaleEffect(isLightningAnimating ? 1.3 : 1.0)
                                .animation(
                                    .easeInOut(duration: 0.5).repeatForever(autoreverses: true),
                                    value: isLightningAnimating
                                )
                            
                            Text("Peer Details")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        // Peer info card
                        VStack(spacing: 16) {
                            // Avatar and basic info
                            VStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [.blue, .purple],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 80, height: 80)
                                    
                                    Text(peerAvatarInitials)
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                                
                                VStack(spacing: 4) {
                                    Text(peer.cardName ?? peer.name)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    
                                    if let title = peer.cardTitle {
                                        Text(title)
                                        .font(.headline)
                                            .foregroundColor(.yellow)
                                    }
                                    
                                    if let company = peer.cardCompany {
                                        Text(company)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            
                            // Status and verification
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Connection Status")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Spacer()
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(statusColor)
                                            .frame(width: 8, height: 8)
                                        Text(peer.status.rawValue)
                                            .font(.subheadline)
                                            .foregroundColor(.white)
                                    }
                                }
                                
                                if let verification = peer.verification {
                                    HStack {
                                        Text("Verification")
                                            .font(.headline)
                                            .foregroundColor(.white)
                            Spacer()
                                HStack(spacing: 6) {
                                            Image(systemName: verification.systemImageName)
                                                .foregroundColor(verificationColor)
                                            Text(verification.displayName)
                                                .font(.subheadline)
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                                
                                if peer.discoveryInfo["zk"] == "1" {
                                    HStack {
                                        Text("ZK Capability")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Spacer()
                                HStack(spacing: 6) {
                                            Image(systemName: "shield.checkerboard")
                                                .foregroundColor(.blue)
                                            Text("Enabled")
                                                .font(.subheadline)
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                                )
                        )
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("Peer Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white)
                }
            }
            .onAppear {
                isLightningAnimating = true
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private var peerAvatarInitials: String {
        let name = peer.cardName ?? peer.name
        let components = name.components(separatedBy: " ")
        let initials = components.compactMap { $0.first }.map { String($0) }
        return initials.prefix(2).joined().uppercased()
    }
    
    private var statusColor: Color {
        switch peer.status {
        case .connected: return .green
        case .connecting: return .orange
        case .disconnected: return .gray
        }
    }
    
    private var verificationColor: Color {
        if let verification = peer.verification {
            switch verification {
            case .verified: return .green
            case .pending: return .orange
            case .unverified: return .blue
            case .failed: return .red
            }
        }
        return .blue
    }
}

// MARK: - Share Card Picker Sheet

private struct ShareCardPickerSheet: View {
    let cards: [BusinessCard]
    let onStart: (BusinessCard, SharingLevel) -> Void
    let onStop: () -> Void
    let isAdvertising: Bool
    @Environment(\ .dismiss) private var dismiss
    @State private var selectedCardId: UUID? = nil
    @State private var level: SharingLevel = .professional
    
    var body: some View {
        NavigationView {
            Form {
                Section("Card") {
                    Picker("Business Card", selection: $selectedCardId) {
                        ForEach(cards) { card in
                            Text(card.name).tag(Optional(card.id))
                        }
                    }
                }
                Section("Privacy Level") {
                    Picker("Level", selection: $level) {
                        ForEach(SharingLevel.allCases, id: \.self) { lvl in
                            Text(lvl.displayName).tag(lvl)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                if let card = cards.first(where: { $0.id == selectedCardId }) {
                    Section("Preview") {
                        BusinessCardPreview(businessCard: card.filteredCard(for: level))
                    }
                }
            }
            .navigationTitle("Share Card")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isAdvertising {
                        Button("Stop") { onStop(); dismiss() }
                    } else {
                        Button("Start") {
                            if let id = selectedCardId, let card = cards.first(where: { $0.id == id }) { onStart(card, level); dismiss() }
                        }
                        .disabled(selectedCardId == nil)
                    }
                }
            }
        }
        .onAppear { if selectedCardId == nil { selectedCardId = cards.first?.id } }
    }
}

#Preview {
    ZStack { Color.black.ignoresSafeArea(); MatchingOrbitView().frame(width: 300, height: 300) }
        .preferredColorScheme(.dark)
}


