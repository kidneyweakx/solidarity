//
//  ContactListView.swift
//  airmeishi
//
//  Contact list view with search, filtering, and organization features
//

import SwiftUI

struct ContactListView: View {
    @StateObject private var contactRepository = ContactRepository.shared
    @State private var searchText = ""
    @State private var selectedSource: ContactSource?
    @State private var selectedVerificationStatus: VerificationStatus?
    @State private var selectedTag: String?
    @State private var showingFilters = false
    @State private var showingContactDetail = false
    @State private var selectedContact: Contact?
    @State private var sortOption: ContactSortOption = .dateReceived
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and Filter Bar
                searchAndFilterBar
                
                // Contact List
                contactList
            }
            .navigationTitle("Contacts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Filters") {
                        showingFilters.toggle()
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                ContactFiltersView(
                    selectedSource: $selectedSource,
                    selectedVerificationStatus: $selectedVerificationStatus,
                    selectedTag: $selectedTag,
                    sortOption: $sortOption
                )
            }
            .sheet(isPresented: $showingContactDetail) {
                if let contact = selectedContact {
                    ContactDetailView(contact: contact)
                }
            }
        }
    }
    
    // MARK: - Search and Filter Bar
    
    private var searchAndFilterBar: some View {
        VStack(spacing: 8) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search contacts...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button("Clear") {
                        searchText = ""
                    }
                    .font(.caption)
                }
            }
            .padding(.horizontal)
            
            // Active Filters
            if hasActiveFilters {
                activeFiltersView
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemGroupedBackground))
    }
    
    private var activeFiltersView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if let source = selectedSource {
                    FilterChip(
                        title: source.displayName,
                        systemImage: source.systemImageName
                    ) {
                        selectedSource = nil
                    }
                }
                
                if let status = selectedVerificationStatus {
                    FilterChip(
                        title: status.displayName,
                        systemImage: status.systemImageName
                    ) {
                        selectedVerificationStatus = nil
                    }
                }
                
                if let tag = selectedTag {
                    FilterChip(
                        title: "#\(tag)",
                        systemImage: "tag"
                    ) {
                        selectedTag = nil
                    }
                }
                
                Button("Clear All") {
                    clearAllFilters()
                }
                .font(.caption)
                .foregroundColor(.red)
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Contact List
    
    private var contactList: some View {
        Group {
            if contactRepository.isLoading {
                ProgressView("Loading contacts...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredContacts.isEmpty {
                emptyStateView
            } else {
                List {
                    ForEach(sortedContacts) { contact in
                        ContactRowView(contact: contact) {
                            selectedContact = contact
                            showingContactDetail = true
                        }
                    }
                    .onDelete(perform: deleteContacts)
                }
                .listStyle(PlainListStyle())
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Contacts Found")
                .font(.title2)
                .fontWeight(.medium)
            
            Text(hasActiveFilters ? "Try adjusting your filters" : "Start collecting business cards to see them here")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if hasActiveFilters {
                Button("Clear Filters") {
                    clearAllFilters()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Computed Properties
    
    private var filteredContacts: [Contact] {
        let allContactsResult = contactRepository.getAllContacts()
        
        guard case .success(let allContacts) = allContactsResult else {
            return []
        }
        
        var contacts = allContacts
        
        // Apply search filter
        if !searchText.isEmpty {
            let searchResult = contactRepository.searchContacts(query: searchText)
            if case .success(let searchedContacts) = searchResult {
                contacts = searchedContacts
            }
        }
        
        // Apply source filter
        if let source = selectedSource {
            contacts = contacts.filter { $0.source == source }
        }
        
        // Apply verification status filter
        if let status = selectedVerificationStatus {
            contacts = contacts.filter { $0.verificationStatus == status }
        }
        
        // Apply tag filter
        if let tag = selectedTag {
            contacts = contacts.filter { $0.tags.contains(tag) }
        }
        
        return contacts
    }
    
    private var sortedContacts: [Contact] {
        switch sortOption {
        case .dateReceived:
            return filteredContacts.sorted { $0.receivedAt > $1.receivedAt }
        case .name:
            return filteredContacts.sorted { $0.businessCard.name < $1.businessCard.name }
        case .company:
            return filteredContacts.sorted { 
                ($0.businessCard.company ?? "") < ($1.businessCard.company ?? "")
            }
        case .lastInteraction:
            return filteredContacts.sorted { 
                ($0.lastInteraction ?? Date.distantPast) > ($1.lastInteraction ?? Date.distantPast)
            }
        }
    }
    
    private var hasActiveFilters: Bool {
        selectedSource != nil || selectedVerificationStatus != nil || selectedTag != nil
    }
    
    // MARK: - Actions
    
    private func clearAllFilters() {
        selectedSource = nil
        selectedVerificationStatus = nil
        selectedTag = nil
    }
    
    private func deleteContacts(at offsets: IndexSet) {
        for index in offsets {
            let contact = sortedContacts[index]
            let _ = contactRepository.deleteContact(id: contact.id)
        }
    }
}

// MARK: - Supporting Views

struct ContactRowView: View {
    let contact: Contact
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Profile Image or Initials
                AsyncImage(url: contact.businessCard.profileImageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.blue.gradient)
                        .overlay {
                            Text(contact.businessCard.initials)
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
                
                // Contact Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(contact.businessCard.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // Verification Status
                        Image(systemName: contact.verificationStatus.systemImageName)
                            .foregroundColor(Color(contact.verificationStatus.color))
                            .font(.caption)
                    }
                    
                    if let company = contact.businessCard.company {
                        Text(company)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        // Source
                        Label(contact.source.displayName, systemImage: contact.source.systemImageName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        // Date
                        Text(contact.receivedAt, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Tags
                    if !contact.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 4) {
                                ForEach(contact.tags.prefix(3), id: \.self) { tag in
                                    Text("#\(tag)")
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(4)
                                }
                                
                                if contact.tags.count > 3 {
                                    Text("+\(contact.tags.count - 3)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FilterChip: View {
    let title: String
    let systemImage: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.caption)
            
            Text(title)
                .font(.caption)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.1))
        .foregroundColor(.blue)
        .cornerRadius(16)
    }
}

// MARK: - Sort Options

enum ContactSortOption: String, CaseIterable, Identifiable {
    case dateReceived = "Date Received"
    case name = "Name"
    case company = "Company"
    case lastInteraction = "Last Interaction"
    
    var id: String { rawValue }
    
    var systemImageName: String {
        switch self {
        case .dateReceived: return "calendar"
        case .name: return "textformat.abc"
        case .company: return "building.2"
        case .lastInteraction: return "clock"
        }
    }
}

#Preview {
    ContactListView()
}