//
//  ContentView.swift
//  airmeishi
//
//  Main app content view with business card management
//

import SwiftUI

struct ContentView: View {
    @State private var showingQRScanner = false
    
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
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
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
