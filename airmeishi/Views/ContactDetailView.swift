//
//  ContactDetailView.swift
//  airmeishi
//
//  Detailed view for a specific contact with editing capabilities
//

import SwiftUI
import MessageUI

struct ContactDetailView: View {
    @State var contact: Contact
    @StateObject private var contactRepository = ContactRepository.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var isEditing = false
    @State private var editingNotes = ""
    @State private var editingTags: [String] = []
    @State private var newTag = ""
    @State private var showingDeleteAlert = false
    @State private var showingShareSheet = false
    @State private var showingMailComposer = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with profile image and basic info
                    headerSection
                    
                    // Business card information
                    businessCardSection
                    
                    // Contact metadata
                    metadataSection
                    
                    // Notes section
                    notesSection
                    
                    // Tags section
                    tagsSection
                    
                    // Actions section
                    actionsSection
                }
                .padding()
            }
            .navigationTitle("Contact Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Save" : "Edit") {
                        if isEditing {
                            saveChanges()
                        } else {
                            startEditing()
                        }
                    }
                }
            }
            .alert("Delete Contact", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    deleteContact()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete this contact? This action cannot be undone.")
            }
            .sheet(isPresented: $showingShareSheet) {
                BusinessCardShareSheet(items: [contact.businessCard.vCardData])
            }
            .sheet(isPresented: $showingMailComposer) {
                if let email = contact.businessCard.email {
                    MailComposerView(
                        recipients: [email],
                        subject: "Following up from our meeting",
                        body: "Hi \(contact.businessCard.name),\n\nIt was great meeting you! "
                    )
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Profile Image
            AsyncImage(url: contact.businessCard.profileImageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.blue.gradient)
                    .overlay {
                        Text(contact.businessCard.initials)
                            .font(.largeTitle)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
            }
            .frame(width: 100, height: 100)
            .clipShape(Circle())
            
            // Name and Title
            VStack(spacing: 4) {
                Text(contact.businessCard.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if let title = contact.businessCard.title {
                    Text(title)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if let company = contact.businessCard.company {
                    Text(company)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            // Verification Status
            HStack {
                Image(systemName: contact.verificationStatus.systemImageName)
                    .foregroundColor(Color(contact.verificationStatus.color))
                
                Text(contact.verificationStatus.displayName)
                    .font(.caption)
                    .foregroundColor(Color(contact.verificationStatus.color))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(contact.verificationStatus.color).opacity(0.1))
            .cornerRadius(16)
        }
    }
    
    // MARK: - Business Card Section
    
    private var businessCardSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Contact Information")
                .font(.headline)
            
            VStack(spacing: 8) {
                if let email = contact.businessCard.email {
                    ActionableContactInfoRow(
                        icon: "envelope",
                        title: "Email",
                        value: email,
                        action: {
                            if MFMailComposeViewController.canSendMail() {
                                showingMailComposer = true
                            } else {
                                // Open mail app
                                if let url = URL(string: "mailto:\(email)") {
                                    UIApplication.shared.open(url)
                                }
                            }
                        }
                    )
                }
                
                if let phone = contact.businessCard.phone {
                    ActionableContactInfoRow(
                        icon: "phone",
                        title: "Phone",
                        value: phone,
                        action: {
                            if let url = URL(string: "tel:\(phone)") {
                                UIApplication.shared.open(url)
                            }
                        }
                    )
                }
                
                if !contact.businessCard.skills.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "star")
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            
                            Text("Skills")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 120))
                        ], spacing: 8) {
                            ForEach(contact.businessCard.skills) { skill in
                                SkillChip(skill: skill)
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Metadata Section
    
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Contact Details")
                .font(.headline)
            
            VStack(spacing: 8) {
                MetadataRow(
                    icon: contact.source.systemImageName,
                    title: "Received via",
                    value: contact.source.displayName
                )
                
                MetadataRow(
                    icon: "calendar",
                    title: "Received on",
                    value: DateFormatter.mediumDate.string(from: contact.receivedAt)
                )
                
                if let lastInteraction = contact.lastInteraction {
                    MetadataRow(
                        icon: "clock",
                        title: "Last interaction",
                        value: DateFormatter.mediumDate.string(from: lastInteraction)
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Notes Section
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(.headline)
            
            if isEditing {
                TextEditor(text: $editingNotes)
                    .frame(minHeight: 100)
                    .padding(8)
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
            } else {
                Text(contact.notes?.isEmpty == false ? contact.notes! : "No notes added")
                    .font(.body)
                    .foregroundColor(contact.notes?.isEmpty == false ? .primary : .secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Tags Section
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tags")
                .font(.headline)
            
            if isEditing {
                VStack(alignment: .leading, spacing: 8) {
                    // Add new tag
                    HStack {
                        TextField("Add tag", text: $newTag)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button("Add") {
                            addTag()
                        }
                        .disabled(newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    
                    // Existing tags
                    if !editingTags.isEmpty {
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 100))
                        ], spacing: 8) {
                            ForEach(editingTags, id: \.self) { tag in
                                TagChip(tag: tag, isEditing: true) {
                                    removeTag(tag)
                                }
                            }
                        }
                    }
                }
            } else {
                if contact.tags.isEmpty {
                    Text("No tags added")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 100))
                    ], spacing: 8) {
                        ForEach(contact.tags, id: \.self) { tag in
                            TagChip(tag: tag, isEditing: false) { }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button(action: { showingShareSheet = true }) {
                Label("Share Contact", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            
            Button(action: { showingDeleteAlert = true }) {
                Label("Delete Contact", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .foregroundColor(.red)
        }
    }
    
    // MARK: - Actions
    
    private func startEditing() {
        isEditing = true
        editingNotes = contact.notes ?? ""
        editingTags = contact.tags
    }
    
    private func saveChanges() {
        var updatedContact = contact
        updatedContact.notes = editingNotes.isEmpty ? nil : editingNotes
        updatedContact.tags = editingTags
        updatedContact.updateInteraction()
        
        let result = contactRepository.updateContact(updatedContact)
        
        switch result {
        case .success(let savedContact):
            contact = savedContact
            isEditing = false
        case .failure(let error):
            print("Failed to save contact: \(error.localizedDescription)")
        }
    }
    
    private func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTag.isEmpty && !editingTags.contains(trimmedTag) {
            editingTags.append(trimmedTag)
            newTag = ""
        }
    }
    
    private func removeTag(_ tag: String) {
        editingTags.removeAll { $0 == tag }
    }
    
    private func deleteContact() {
        let result = contactRepository.deleteContact(id: contact.id)
        
        switch result {
        case .success:
            dismiss()
        case .failure(let error):
            print("Failed to delete contact: \(error.localizedDescription)")
        }
    }
}

// MARK: - Supporting Views
// Shared components are now in SharedComponents.swift

// MARK: - Extensions

extension DateFormatter {
    static let mediumDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}

#Preview {
    ContactDetailView(
        contact: Contact(
            businessCard: BusinessCard.sample,
            source: .qrCode,
            tags: ["colleague", "tech"],
            notes: "Met at tech conference"
        )
    )
}