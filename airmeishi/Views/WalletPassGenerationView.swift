//
//  WalletPassGenerationView.swift
//  airmeishi
//
//  Apple Wallet pass generation interface with PassKit integration
//

import SwiftUI
import PassKit

/// Apple Wallet pass generation and management view
struct WalletPassGenerationView: View {
    let businessCard: BusinessCard
    let sharingLevel: SharingLevel
    
    @StateObject private var passKitManager = PassKitManager.shared
    @State private var showingAddToWallet = false
    @State private var generatedPassData: Data?
    @State private var showingError = false
    @State private var errorMessage = ""
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "wallet.pass")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Apple Wallet Pass")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Create a pass for Apple Wallet that contains your business card information")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    
                    // Pass preview
                    PassPreviewView(
                        businessCard: businessCard.filteredCard(for: sharingLevel),
                        sharingLevel: sharingLevel
                    )
                    
                    // Generation status
                    if passKitManager.isGeneratingPass {
                        VStack(spacing: 12) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                            
                            Text("Generating pass...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        if generatedPassData != nil {
                            Button(action: addToWallet) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add to Apple Wallet")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                            }
                        } else {
                            Button(action: generatePass) {
                                HStack {
                                    Image(systemName: "doc.badge.plus")
                                    Text("Generate Pass")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                            }
                            .disabled(passKitManager.isGeneratingPass)
                        }
                        
                        Button("Cancel") {
                            dismiss()
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // Information section
                    PassInformationView()
                }
                .padding()
            }
            .navigationTitle("Wallet Pass")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showingAddToWallet) {
            if let passData = generatedPassData {
                AddToWalletView(passData: passData)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func generatePass() {
        let result = passKitManager.generatePass(
            for: businessCard,
            sharingLevel: sharingLevel
        )
        
        switch result {
        case .success(let passData):
            generatedPassData = passData
        case .failure(let error):
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    private func addToWallet() {
        guard let passData = generatedPassData else { return }
        
        let result = passKitManager.addPassToWallet(passData)
        
        switch result {
        case .success:
            showingAddToWallet = true
        case .failure(let error):
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

// MARK: - Pass Preview

struct PassPreviewView: View {
    let businessCard: BusinessCard
    let sharingLevel: SharingLevel
    
    var body: some View {
        VStack(spacing: 0) {
            // Pass header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Airmeishi")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Text("Business Card")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                Image(systemName: "person.crop.circle")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.blue, Color.blue.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            
            // Pass content
            VStack(alignment: .leading, spacing: 12) {
                // Primary field
                VStack(alignment: .leading, spacing: 4) {
                    Text("NAME")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(businessCard.name)
                        .font(.title3)
                        .fontWeight(.bold)
                }
                
                // Secondary fields
                HStack {
                    if let title = businessCard.title {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("TITLE")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Text(title)
                                .font(.subheadline)
                        }
                    }
                    
                    Spacer()
                    
                    if let company = businessCard.company {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("COMPANY")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Text(company)
                                .font(.subheadline)
                        }
                    }
                }
                
                // Auxiliary fields
                HStack {
                    if let email = businessCard.email {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("EMAIL")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Text(email)
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Spacer()
                    
                    if let phone = businessCard.phone {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("PHONE")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Text(phone)
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                // QR code placeholder
                HStack {
                    Spacer()
                    
                    VStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "qrcode")
                                    .font(.title)
                                    .foregroundColor(.white)
                            )
                        
                        Text("QR Code")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .cornerRadius(12)
        .shadow(radius: 8)
        .padding(.horizontal)
    }
}

// MARK: - Pass Information

struct PassInformationView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("About Apple Wallet Passes")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                InfoRow(
                    icon: "checkmark.circle",
                    title: "Always Available",
                    description: "Access your business card even when offline"
                )
                
                InfoRow(
                    icon: "lock.shield",
                    title: "Secure Sharing",
                    description: "QR code contains encrypted information"
                )
                
                InfoRow(
                    icon: "arrow.clockwise",
                    title: "Auto Updates",
                    description: "Pass updates automatically when you change your information"
                )
                
                InfoRow(
                    icon: "person.2",
                    title: "Easy Sharing",
                    description: "Recipients can scan your pass to get your contact info"
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.green)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Add to Wallet View

struct AddToWalletView: View {
    let passData: Data
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)
                    
                    Text("Pass Generated Successfully!")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Your business card pass has been created and is ready to be added to Apple Wallet.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 12) {
                    Text("Next Steps:")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("1. The pass will appear in your Wallet app")
                        Text("2. You can share it by showing the QR code")
                        Text("3. Others can scan it to get your contact info")
                        Text("4. The pass will update automatically when you change your information")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
            .padding()
            .navigationTitle("Success")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    WalletPassGenerationView(
        businessCard: BusinessCard(
            name: "John Doe",
            title: "Software Engineer",
            company: "Tech Corp",
            email: "john@techcorp.com",
            phone: "+1 (555) 123-4567"
        ),
        sharingLevel: .professional
    )
}