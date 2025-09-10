//
//  BusinessCardListView.swift
//  airmeishi
//
//  Main view for displaying and managing business cards
//

import SwiftUI

struct BusinessCardListView: View {
    @StateObject private var cardManager = CardManager.shared
    @State private var showingCreateCard = false
    @State private var showingOCRScanner = false
    @State private var searchText = ""
    @State private var selectedCard: BusinessCard?
    @State private var showingCardDetail = false
    
    var body: some View {
        NavigationView {
            VStack {
                if cardManager.isLoading {
                    ProgressView("Loading cards...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredCards.isEmpty {
                    emptyStateView
                } else {
                    cardListView
                }
            }
            .navigationTitle("My Cards")
            .searchable(text: $searchText, prompt: "Search cards...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Create New Card") {
                            showingCreateCard = true
                        }
                        
                        Button("Scan Business Card") {
                            showingOCRScanner = true
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateCard) {
                BusinessCardFormView { savedCard in
                    // Card saved successfully
                }
            }
            .sheet(isPresented: $showingOCRScanner) {
                OCRScannerView { extractedCard in
                    // Show form with extracted data
                    selectedCard = extractedCard
                    showingCreateCard = true
                }
            }
            .sheet(item: $selectedCard) { card in
                BusinessCardFormView(businessCard: card) { savedCard in
                    // Card updated successfully
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredCards: [BusinessCard] {
        if searchText.isEmpty {
            return cardManager.businessCards
        } else {
            let result = cardManager.searchCards(query: searchText)
            switch result {
            case .success(let cards):
                return cards
            case .failure:
                return []
            }
        }
    }
    
    // MARK: - View Components
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.crop.rectangle")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("No Business Cards")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Create your first business card or scan an existing one to get started")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                Button("Create New Card") {
                    showingCreateCard = true
                }
                .buttonStyle(.borderedProminent)
                
                Button("Scan Business Card") {
                    showingOCRScanner = true
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var cardListView: some View {
        List {
            ForEach(filteredCards) { card in
                BusinessCardRowView(card: card) {
                    selectedCard = card
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button("Delete", role: .destructive) {
                        deleteCard(card)
                    }
                    
                    Button("Edit") {
                        selectedCard = card
                    }
                    .tint(.blue)
                    
                    Button("Share") {
                        // This will be handled by the QR button in the row
                    }
                    .tint(.green)
                }
            }
        }
        .refreshable {
            cardManager.refreshCards()
        }
    }
    
    // MARK: - Methods
    
    private func deleteCard(_ card: BusinessCard) {
        let result = cardManager.deleteCard(id: card.id)
        
        switch result {
        case .success:
            // Card deleted successfully
            break
        case .failure(let error):
            // Handle error - could show alert
            print("Failed to delete card: \(error.localizedDescription)")
        }
    }
}

// MARK: - Supporting Views

struct BusinessCardRowView: View {
    let card: BusinessCard
    let onTap: () -> Void
    
    @State private var showingQRSharing = false
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onTap) {
                HStack(spacing: 12) {
                    // Profile image or placeholder
                    if let imageData = card.profileImage,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 50, height: 50)
                            .overlay {
                                Text(card.name.prefix(1).uppercased())
                                    .font(.title2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.gray)
                            }
                    }
                    
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
                        
                        if !card.skills.isEmpty {
                            HStack {
                                Image(systemName: "star.fill")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                                
                                Text("\(card.skills.count) skills")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(card.updatedAt, style: .date)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)
            
            // QR Share button
            Button(action: { showingQRSharing = true }) {
                Image(systemName: "qrcode")
                    .font(.title3)
                    .foregroundColor(.blue)
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $showingQRSharing) {
            QRSharingView(businessCard: card)
        }
    }
}

#Preview {
    BusinessCardListView()
}