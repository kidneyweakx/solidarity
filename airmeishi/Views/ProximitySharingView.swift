//
//  ProximitySharingView.swift
//  airmeishi
//
//  UI for proximity-based sharing with nearby user selection and device discovery
//

import SwiftUI
import MultipeerConnectivity

/// Main view for proximity-based sharing functionality
struct ProximitySharingView: View {
    @StateObject private var proximityManager = ProximityManager.shared
    @StateObject private var cardManager = CardManager.shared
    @StateObject private var airDropManager = AirDropManager.shared
    
    @State private var selectedCard: BusinessCard?
    @State private var selectedSharingLevel: SharingLevel = .professional
    @State private var showingCardPicker = false
    @State private var showingShareOptions = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header with status
                statusHeaderView
                
                // Card selection section
                cardSelectionSection
                
                // Sharing controls
                sharingControlsSection
                
                // Nearby peers list
                nearbyPeersSection
                
                // Received cards section
                receivedCardsSection
                
                Spacer()
            }
            .padding()
            .navigationTitle("Proximity Sharing")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        proximityManager.disconnect()
                    }
                }
            }
        }
        .sheet(isPresented: $showingCardPicker) {
            cardPickerSheet
        }
        .sheet(isPresented: $showingShareOptions) {
            shareOptionsSheet
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .onReceive(proximityManager.$lastError) { error in
            if let error = error {
                errorMessage = error.localizedDescription
                showingErrorAlert = true
            }
        }
        .onAppear {
            // Select first card by default
            if selectedCard == nil, let firstCard = cardManager.businessCards.first {
                selectedCard = firstCard
            }
        }
    }
    
    // MARK: - Status Header
    
    private var statusHeaderView: some View {
        VStack(spacing: 12) {
            // Connection status indicator
            HStack {
                Image(systemName: proximityManager.connectionStatus.systemImageName)
                    .foregroundColor(statusColor)
                    .font(.title2)
                
                Text(proximityManager.connectionStatus.displayName)
                    .font(.headline)
                    .foregroundColor(statusColor)
            }
            .padding()
            .background(statusColor.opacity(0.1))
            .cornerRadius(12)
            
            // Statistics
            HStack(spacing: 20) {
                statusStatView(
                    title: "Nearby",
                    value: "\(proximityManager.nearbyPeers.count)",
                    icon: "person.2.wave.2"
                )
                
                statusStatView(
                    title: "Connected",
                    value: "\(proximityManager.getSharingStatus().connectedPeersCount)",
                    icon: "link"
                )
                
                statusStatView(
                    title: "Received",
                    value: "\(proximityManager.receivedCards.count)",
                    icon: "tray.and.arrow.down"
                )
            }
        }
    }
    
    private func statusStatView(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var statusColor: Color {
        switch proximityManager.connectionStatus {
        case .disconnected:
            return .gray
        case .advertising, .browsing:
            return .orange
        case .advertisingAndBrowsing, .connected:
            return .green
        }
    }
    
    // MARK: - Card Selection
    
    private var cardSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Card to Share")
                .font(.headline)
            
            if let card = selectedCard {
                selectedCardView(card)
            } else {
                noCardSelectedView
            }
            
            // Sharing level picker
            sharingLevelPicker
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func selectedCardView(_ card: BusinessCard) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(card.name)
                    .font(.headline)
                
                if let title = card.title {
                    Text(title)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if let company = card.company {
                    Text(company)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button("Change") {
                showingCardPicker = true
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    private var noCardSelectedView: some View {
        Button(action: { showingCardPicker = true }) {
            HStack {
                Image(systemName: "plus.circle")
                Text("Select a business card")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(8)
        }
    }
    
    private var sharingLevelPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Privacy Level")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Picker("Sharing Level", selection: $selectedSharingLevel) {
                ForEach(SharingLevel.allCases) { level in
                    Text(level.displayName).tag(level)
                }
            }
            .pickerStyle(.segmented)
        }
    }
    
    // MARK: - Sharing Controls
    
    private var sharingControlsSection: some View {
        VStack(spacing: 12) {
            Text("Sharing Controls")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                // Start/Stop Advertising
                Button(action: toggleAdvertising) {
                    HStack {
                        Image(systemName: proximityManager.isAdvertising ? "stop.circle" : "dot.radiowaves.left.and.right")
                        Text(proximityManager.isAdvertising ? "Stop Sharing" : "Start Sharing")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedCard == nil)
                
                // Start/Stop Browsing
                Button(action: toggleBrowsing) {
                    HStack {
                        Image(systemName: proximityManager.isBrowsing ? "stop.circle" : "magnifyingglass")
                        Text(proximityManager.isBrowsing ? "Stop Looking" : "Find Others")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            
            // AirDrop button
            if airDropManager.canShareViaAirDrop() {
                Button(action: shareViaAirDrop) {
                    HStack {
                        Image(systemName: "airplayaudio")
                        Text("Share via AirDrop")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(selectedCard == nil || airDropManager.isSharing)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Nearby Peers
    
    private var nearbyPeersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Nearby People")
                    .font(.headline)
                
                Spacer()
                
                if proximityManager.isBrowsing {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            if proximityManager.nearbyPeers.isEmpty {
                emptyPeersView
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(proximityManager.nearbyPeers) { peer in
                        peerRowView(peer)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var emptyPeersView: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.2.slash")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text(proximityManager.isBrowsing ? "Looking for nearby people..." : "Tap 'Find Others' to discover nearby people")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    private func peerRowView(_ peer: ProximityPeer) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(peer.name)
                    .font(.headline)
                
                if let cardName = peer.cardName {
                    Text(cardName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if let title = peer.cardTitle, let company = peer.cardCompany {
                    Text("\(title) at \(company)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if let title = peer.cardTitle {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if let company = peer.cardCompany {
                    Text(company)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                // Connection status
                HStack(spacing: 4) {
                    Image(systemName: peer.status.systemImageName)
                        .foregroundColor(Color(peer.status.color))
                        .font(.caption)
                    
                    Text(peer.status.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Action button
                if peer.status == .disconnected {
                    Button("Connect") {
                        proximityManager.connectToPeer(peer)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                } else if peer.status == .connected {
                    Button("Send Card") {
                        sendCardToPeer(peer)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(selectedCard == nil)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    // MARK: - Received Cards
    
    private var receivedCardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Received Cards")
                    .font(.headline)
                
                Spacer()
                
                if !proximityManager.receivedCards.isEmpty {
                    Button("Clear") {
                        proximityManager.clearReceivedCards()
                    }
                    .font(.caption)
                }
            }
            
            if proximityManager.receivedCards.isEmpty {
                emptyReceivedCardsView
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(proximityManager.receivedCards) { card in
                        receivedCardRowView(card)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var emptyReceivedCardsView: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("No cards received yet")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    private func receivedCardRowView(_ card: BusinessCard) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(card.name)
                    .font(.headline)
                
                if let title = card.title {
                    Text(title)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if let company = card.company {
                    Text(company)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    // MARK: - Sheets
    
    private var cardPickerSheet: some View {
        NavigationView {
            List {
                ForEach(cardManager.businessCards) { card in
                    Button(action: {
                        selectedCard = card
                        showingCardPicker = false
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(card.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                if let title = card.title {
                                    Text(title)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                if let company = card.company {
                                    Text(company)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if selectedCard?.id == card.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        showingCardPicker = false
                    }
                }
            }
        }
    }
    
    private var shareOptionsSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Share Options")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                // Implementation for additional share options
                Text("Additional sharing options will be implemented here")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingShareOptions = false
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func toggleAdvertising() {
        if proximityManager.isAdvertising {
            proximityManager.stopAdvertising()
        } else if let card = selectedCard {
            proximityManager.startAdvertising(with: card, sharingLevel: selectedSharingLevel)
        }
    }
    
    private func toggleBrowsing() {
        if proximityManager.isBrowsing {
            proximityManager.stopBrowsing()
        } else {
            proximityManager.startBrowsing()
        }
    }
    
    private func sendCardToPeer(_ peer: ProximityPeer) {
        guard let card = selectedCard else { return }
        proximityManager.sendCard(card, to: peer.peerID, sharingLevel: selectedSharingLevel)
    }
    
    private func shareViaAirDrop() {
        guard let card = selectedCard else { return }
        
        // Get the root view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            
            airDropManager.shareBusinessCard(card, sharingLevel: selectedSharingLevel, from: rootViewController)
        }
    }
}

// MARK: - Preview

struct ProximitySharingView_Previews: PreviewProvider {
    static var previews: some View {
        ProximitySharingView()
    }
}