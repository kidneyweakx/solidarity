//
//  ContentView.swift
//  airmeishi
//
//  Main app content view with business card management
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var deepLinkManager: DeepLinkManager
    @State private var showingQRScanner = false
    @State private var showingReceivedCard = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        TabView {
            BusinessCardListView()
                .tabItem {
                    Image(systemName: "person.crop.rectangle")
                    Text("My Cards")
                }
            
            ContactListView()
                .tabItem {
                    Image(systemName: "person.2")
                    Text("Contacts")
                }
            
            QRScannerTabView()
                .tabItem {
                    Image(systemName: "qrcode.viewfinder")
                    Text("Scan")
                }
            
            ProximitySharingTabView()
                .tabItem {
                    Image(systemName: "wave.3.right")
                    Text("Share")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
        .sheet(isPresented: $showingReceivedCard) {
            if let card = deepLinkManager.lastReceivedCard {
                ReceivedCardView(card: card)
            }
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .onReceive(deepLinkManager.$pendingAction) { action in
            handleDeepLinkAction(action)
        }
    }
    
    private func handleDeepLinkAction(_ action: DeepLinkAction?) {
        guard let action = action else { return }
        
        switch action {
        case .showReceivedCard:
            showingReceivedCard = true
            
        case .showError(let message):
            errorMessage = message
            showingErrorAlert = true
            
        case .navigateToSharing:
            // Navigate to sharing tab
            break
            
        case .navigateToContacts:
            // Navigate to contacts tab
            break
        }
        
        // Clear the action after handling
        deepLinkManager.clearPendingAction()
    }
}

// MARK: - QR Scanner Tab View

struct QRScannerTabView: View {
    @State private var showingScanner = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                VStack(spacing: 16) {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("Scan QR Code")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Scan business card QR codes to instantly add contacts")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Button(action: { showingScanner = true }) {
                    HStack {
                        Image(systemName: "camera")
                        Text("Start Scanning")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("QR Scanner")
        }
        .fullScreenCover(isPresented: $showingScanner) {
            QRScannerView()
        }
    }
}

// MARK: - Proximity Sharing Tab View

struct ProximitySharingTabView: View {
    @State private var showingProximitySharing = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                VStack(spacing: 16) {
                    Image(systemName: "wave.3.right")
                        .font(.system(size: 80))
                        .foregroundColor(.green)
                    
                    Text("Proximity Sharing")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Share your business card with nearby people using iPhone touch or AirDrop")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                VStack(spacing: 12) {
                    Button(action: { showingProximitySharing = true }) {
                        HStack {
                            Image(systemName: "dot.radiowaves.left.and.right")
                            Text("Start Proximity Sharing")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                    }
                    
                    Text("Share via AirDrop, Multipeer Connectivity, or QR codes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Share")
        }
        .fullScreenCover(isPresented: $showingProximitySharing) {
            ProximitySharingView()
        }
    }
}

// MARK: - Received Card View

struct ReceivedCardView: View {
    let card: BusinessCard
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Success indicator
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("Business Card Received!")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("The business card has been saved to your contacts")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    
                    // Card preview
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Card Details")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(card.name)
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            if let title = card.title {
                                Text(title)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            if let company = card.company {
                                Text(company)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            if let email = card.email {
                                Text(email)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            
                            if let phone = card.phone {
                                Text(phone)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Card Received")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Placeholder Views

struct ContactListView: View {
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "person.2")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                
                Text("Contacts")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Received business cards will appear here")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .navigationTitle("Contacts")
        }
    }
}

struct SettingsView: View {
    var body: some View {
        NavigationView {
            Form {
                Section("Privacy") {
                    NavigationLink("Default Privacy Settings") {
                        Text("Privacy settings will be implemented in future tasks")
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    ContentView()
}
