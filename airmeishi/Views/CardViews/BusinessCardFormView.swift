//
//  BusinessCardFormView.swift
//  airmeishi
//
//  Complete business card creation and editing form with skills categorization
//

import SwiftUI
import PhotosUI

struct BusinessCardFormView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var cardManager = CardManager.shared
    
    @State private var businessCard: BusinessCard
    @State private var isEditing: Bool
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingOCRScanner = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var showingWalletPassSheet = false
    @State private var createdCardForWallet: BusinessCard?
    
    // Social network management
    @State private var newSocialPlatform = SocialPlatform.linkedin
    @State private var newSocialUsername = ""
    @State private var newSocialUrl = ""
    @State private var showingSocialForm = false
    
    // Validation states
    @State private var nameError: String?
    @State private var emailError: String?
    @State private var phoneError: String?
    
    let onSave: (BusinessCard) -> Void
    
    init(businessCard: BusinessCard? = nil, forceCreate: Bool = false, onSave: @escaping (BusinessCard) -> Void) {
        let initialCard = businessCard ?? BusinessCard(name: "")
        self._businessCard = State(initialValue: initialCard)
        if forceCreate {
            self._isEditing = State(initialValue: false)
        } else if let bc = businessCard {
            // Only treat as editing if the card already exists in storage
            let exists: Bool
            switch CardManager.shared.getCard(id: bc.id) {
            case .success:
                exists = true
            case .failure:
                exists = false
            }
            self._isEditing = State(initialValue: exists)
        } else {
            self._isEditing = State(initialValue: false)
        }
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            Form {
                basicInfoSection
                contactInfoSection
                animalSection
                socialNetworksSection
                simplePrivacySection
                if businessCard.sharingPreferences.useZK {
                    Section {
                        ZKVerifyButton(businessCard: businessCard, sharingLevel: .professional)
                    } header: {
                        Text("ZK Tools")
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Card" : "New Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveBusinessCard()
                    }
                    .disabled(isLoading || !isFormValid)
                }
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            // OCR scanner removed per new flow
            .photosPicker(isPresented: $showingImagePicker, selection: $selectedPhotoItem, matching: .images)
            .onChange(of: selectedPhotoItem) { _, newItem in
                loadSelectedImage(newItem)
            }
            .sheet(isPresented: $showingWalletPassSheet, onDismiss: { dismiss() }) {
                if let card = createdCardForWallet {
                    WalletPassGenerationView(
                        businessCard: card,
                        sharingLevel: .professional
                    )
                }
            }
        }
        .hideKeyboardAccessory()
    }
    
    // MARK: - Form Sections
    
    private var socialNetworksSection: some View {
        Section {
            ForEach(businessCard.socialNetworks) { social in
                SocialNetworkRowView(social: social) {
                    removeSocialNetwork(social)
                }
            }
            .onDelete(perform: deleteSocialNetworks)
            
            Button("Add Social Network") {
                showingSocialForm = true
            }
            .disabled(businessCard.socialNetworks.count >= 2)
            .foregroundColor(.blue)
        } header: {
            Text("Social Networks")
        } footer: {
            Text("Add up to 2 social networks or websites")
        }
        .sheet(isPresented: $showingSocialForm) {
            SocialNetworkFormView(
                platform: $newSocialPlatform,
                username: $newSocialUsername,
                url: $newSocialUrl
            ) { social in
                addSocialNetwork(social)
                showingSocialForm = false
            }
        }
    }
    
    private var simplePrivacySection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { businessCard.sharingPreferences.useZK },
                set: { businessCard.sharingPreferences.useZK = $0 }
            )) {
                Text("Use ZK Selective Disclosure")
            }
            Text("When enabled, your public QR will reveal minimal info. You can switch to Advanced to fine-tune.")
                .font(.caption)
                .foregroundColor(.secondary)
        } header: {
            Text("Privacy")
        }
    }

    
    private var basicInfoSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 4) {
                // Show selected group read-only at top
                if let gid = SemaphoreGroupManager.shared.selectedGroupId,
                   let g = SemaphoreGroupManager.shared.allGroups.first(where: { $0.id == gid }) {
                    HStack {
                        Text("Group").foregroundColor(.secondary)
                        Spacer()
                        Text(g.name).font(.headline)
                    }
                }
                TextField("Full Name", text: $businessCard.name)
                    .textContentType(.name)
                    .onChange(of: businessCard.name) { _, _ in
                        validateName()
                    }
                if let error = nameError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            // Re-enable Job Title input (even with group), but keep company hidden
            TextField("Job Title", text: Binding(
                get: { businessCard.title ?? "" },
                set: { businessCard.title = $0.isEmpty ? nil : $0 }
            ))
            .textContentType(.jobTitle)
        } header: {
            Text("Basic Information")
        }
    }
    
    private var contactInfoSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 4) {
                TextField("Email", text: Binding(
                    get: { businessCard.email ?? "" },
                    set: { businessCard.email = $0.isEmpty ? nil : $0 }
                ))
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .onChange(of: businessCard.email) { _, _ in
                    validateEmail()
                }
                
                if let error = emailError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                TextField("Phone", text: Binding(
                    get: { businessCard.phone ?? "" },
                    set: { businessCard.phone = $0.isEmpty ? nil : $0 }
                ))
                .textContentType(.telephoneNumber)
                .keyboardType(.phonePad)
                .onChange(of: businessCard.phone) { _, _ in
                    validatePhone()
                }
                
                if let error = phoneError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            // Scan business card removed per new flow
        } header: {
            Text("Contact Information (Sensitive Information)")
        }
    }

    private var animalSection: some View {
        Section {
            AnimalSelectorView(selection: Binding(
                get: { businessCard.animal ?? .dog },
                set: { businessCard.animal = $0 }
            ))
        } header: {
            Text("Card Character")
        } footer: {
            if let animal = businessCard.animal {
                Text(animal.personality).font(.caption).foregroundColor(.secondary)
            } else {
                EmptyView()
            }
        }
    }
    
    
    // MARK: - Computed Properties
    
    private var isFormValid: Bool {
        !businessCard.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        nameError == nil &&
        emailError == nil &&
        phoneError == nil
    }
    
    // MARK: - Methods
    
    private func saveBusinessCard() {
        isLoading = true
        
        let result = isEditing ? 
            cardManager.updateCard(businessCard) : 
            cardManager.createCard(businessCard)
        
        switch result {
        case .success(let savedCard):
            onSave(savedCard)
            if isEditing {
                dismiss()
            } else {
                createdCardForWallet = savedCard
                showingWalletPassSheet = true
            }
        case .failure(let error):
            alertMessage = error.localizedDescription
            showingAlert = true
        }
        
        isLoading = false
    }
    
    private func validateName() {
        let trimmedName = businessCard.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            nameError = "Name is required"
        } else {
            nameError = nil
        }
    }
    
    private func validateEmail() {
        guard let email = businessCard.email, !email.isEmpty else {
            emailError = nil
            return
        }
        
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        if !emailPredicate.evaluate(with: email) {
            emailError = "Invalid email format"
        } else {
            emailError = nil
        }
    }
    
    private func validatePhone() {
        guard let phone = businessCard.phone, !phone.isEmpty else {
            phoneError = nil
            return
        }
        
        let phoneRegex = "^[+]?[0-9\\s\\-\\(\\)]{10,}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        
        if !phonePredicate.evaluate(with: phone) {
            phoneError = "Invalid phone format"
        } else {
            phoneError = nil
        }
    }
    
    private func addSocialNetwork(_ social: SocialNetwork) {
        if businessCard.socialNetworks.count < 2 {
            businessCard.socialNetworks.append(social)
        }
    }
    
    private func removeSocialNetwork(_ social: SocialNetwork) {
        businessCard.socialNetworks.removeAll { $0.id == social.id }
    }
    
    private func deleteSocialNetworks(at offsets: IndexSet) {
        businessCard.socialNetworks.remove(atOffsets: offsets)
    }
    
    private func loadSelectedImage(_ item: PhotosPickerItem?) {
        guard let item = item else { return }
        
        item.loadTransferable(type: Data.self) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    if let data = data {
                        businessCard.profileImage = data
                    }
                case .failure(let error):
                    alertMessage = "Failed to load image: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
    
    private func applyExtractedData(_ extractedCard: BusinessCard) {
        // Apply OCR extracted data to current card
        if !extractedCard.name.isEmpty {
            businessCard.name = extractedCard.name
        }
        if let title = extractedCard.title, !title.isEmpty {
            businessCard.title = title
        }
        if let company = extractedCard.company, !company.isEmpty {
            businessCard.company = company
        }
        if let email = extractedCard.email, !email.isEmpty {
            businessCard.email = email
        }
        if let phone = extractedCard.phone, !phone.isEmpty {
            businessCard.phone = phone
        }
        
        // Validate after applying extracted data
        validateName()
        validateEmail()
        validatePhone()
    }
}

#Preview {
    BusinessCardFormView { _ in }
}