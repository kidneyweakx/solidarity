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
    @State private var isSimpleMode = true
    
    // Skills management
    @State private var newSkillName = ""
    @State private var newSkillCategory = ""
    @State private var newSkillProficiency = ProficiencyLevel.intermediate
    @State private var showingSkillForm = false
    
    // Validation states
    @State private var nameError: String?
    @State private var emailError: String?
    @State private var phoneError: String?
    
    let onSave: (BusinessCard) -> Void
    
    init(businessCard: BusinessCard? = nil, onSave: @escaping (BusinessCard) -> Void) {
        self._businessCard = State(initialValue: businessCard ?? BusinessCard(name: ""))
        self._isEditing = State(initialValue: businessCard != nil)
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker("Mode", selection: $isSimpleMode) {
                        Text("Simple").tag(true)
                        Text("Advanced").tag(false)
                    }
                    .pickerStyle(.segmented)
                }
                profileImageSection
                basicInfoSection
                contactInfoSection
                if !isSimpleMode {
                    skillsSection
                    categoriesSection
                    privacySection
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
            .sheet(isPresented: $showingOCRScanner) {
                OCRScannerView { extractedCard in
                    applyExtractedData(extractedCard)
                }
            }
            .photosPicker(isPresented: $showingImagePicker, selection: $selectedPhotoItem, matching: .images)
            .onChange(of: selectedPhotoItem) { _, newItem in
                loadSelectedImage(newItem)
            }
        }
    }
    
    // MARK: - Form Sections
    
    private var profileImageSection: some View {
        Section {
            HStack {
                Spacer()
                
                VStack(spacing: 12) {
                    if let imageData = businessCard.profileImage,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 100, height: 100)
                            .overlay {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                            }
                    }
                    
                    HStack(spacing: 16) {
                        Button("Camera") {
                            showingCamera = true
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Photos") {
                            showingImagePicker = true
                        }
                        .buttonStyle(.bordered)
                        
                        if businessCard.profileImage != nil {
                            Button("Remove") {
                                businessCard.profileImage = nil
                            }
                            .buttonStyle(.bordered)
                            .foregroundColor(.red)
                        }
                    }
                }
                
                Spacer()
            }
        }
    }
    
    private var basicInfoSection: some View {
        Section("Basic Information") {
            VStack(alignment: .leading, spacing: 4) {
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
            
            TextField("Job Title", text: Binding(
                get: { businessCard.title ?? "" },
                set: { businessCard.title = $0.isEmpty ? nil : $0 }
            ))
            .textContentType(.jobTitle)
            
            TextField("Company", text: Binding(
                get: { businessCard.company ?? "" },
                set: { businessCard.company = $0.isEmpty ? nil : $0 }
            ))
            .textContentType(.organizationName)
        }
    }
    
    private var contactInfoSection: some View {
        Section("Contact Information") {
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
            
            Button("Scan Business Card") {
                showingOCRScanner = true
            }
            .foregroundColor(.blue)
        }
    }
    
    private var skillsSection: some View {
        Section {
            ForEach(businessCard.skills) { skill in
                SkillRowView(skill: skill) {
                    removeSkill(skill)
                }
            }
            .onDelete(perform: deleteSkills)
            
            Button("Add Skill") {
                showingSkillForm = true
            }
            .foregroundColor(.blue)
        } header: {
            Text("Skills & Expertise")
        } footer: {
            Text("Add your professional skills and expertise areas")
        }
        .sheet(isPresented: $showingSkillForm) {
            SkillFormView(
                skillName: $newSkillName,
                skillCategory: $newSkillCategory,
                proficiencyLevel: $newSkillProficiency
            ) { skill in
                addSkill(skill)
                showingSkillForm = false
            }
        }
    }
    
    private var categoriesSection: some View {
        Section {
            if businessCard.categories.isEmpty {
                Text("No categories added")
                    .foregroundColor(.gray)
                    .italic()
            } else {
                ForEach(businessCard.categories, id: \.self) { category in
                    HStack {
                        Text(category)
                        Spacer()
                        Button("Remove") {
                            removeCategory(category)
                        }
                        .foregroundColor(.red)
                        .font(.caption)
                    }
                }
            }
            
            Button("Add Category") {
                // This would show a category picker or input
                // For now, we'll derive categories from skills
                updateCategoriesFromSkills()
            }
            .foregroundColor(.blue)
        } header: {
            Text("Categories")
        } footer: {
            Text("Categories help organize and find your cards")
        }
    }
    
    private var privacySection: some View {
        Section {
            NavigationLink("Privacy Settings") {
                PrivacySettingsView(sharingPreferences: $businessCard.sharingPreferences)
            }
        } header: {
            Text("Privacy & Sharing")
        } footer: {
            Text("Control what information is shared and with whom")
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
            dismiss()
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
    
    private func addSkill(_ skill: Skill) {
        businessCard.skills.append(skill)
        updateCategoriesFromSkills()
    }
    
    private func removeSkill(_ skill: Skill) {
        businessCard.skills.removeAll { $0.id == skill.id }
        updateCategoriesFromSkills()
    }
    
    private func deleteSkills(at offsets: IndexSet) {
        businessCard.skills.remove(atOffsets: offsets)
        updateCategoriesFromSkills()
    }
    
    private func removeCategory(_ category: String) {
        businessCard.categories.removeAll { $0 == category }
    }
    
    private func updateCategoriesFromSkills() {
        let skillCategories = Set(businessCard.skills.map { $0.category })
        businessCard.categories = Array(skillCategories).sorted()
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

// MARK: - Supporting Views

struct SkillRowView: View {
    let skill: Skill
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(skill.name)
                    .font(.body)
                
                HStack {
                    Text(skill.category)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(skill.proficiencyLevel.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            Button("Remove") {
                onRemove()
            }
            .foregroundColor(.red)
            .font(.caption)
        }
    }
}

#Preview {
    BusinessCardFormView { _ in }
}