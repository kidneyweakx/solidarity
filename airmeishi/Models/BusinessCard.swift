//
//  BusinessCard.swift
//  airmeishi
//
//  Core data model for business cards with privacy controls and skills management
//

import Foundation

/// Main business card data model with comprehensive contact information and privacy controls
struct BusinessCard: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var title: String?
    var company: String?
    var email: String?
    var phone: String?
    var profileImage: Data?
    var skills: [Skill]
    var categories: [String]
    var sharingPreferences: SharingPreferences
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        title: String? = nil,
        company: String? = nil,
        email: String? = nil,
        phone: String? = nil,
        profileImage: Data? = nil,
        skills: [Skill] = [],
        categories: [String] = [],
        sharingPreferences: SharingPreferences = SharingPreferences(),
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.title = title
        self.company = company
        self.email = email
        self.phone = phone
        self.profileImage = profileImage
        self.skills = skills
        self.categories = categories
        self.sharingPreferences = sharingPreferences
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    /// Update the business card and refresh the updatedAt timestamp
    mutating func update() {
        self.updatedAt = Date()
    }
    
    /// Get filtered business card based on sharing preferences for a specific sharing level
    func filteredCard(for sharingLevel: SharingLevel) -> BusinessCard {
        var filtered = self
        let allowedFields = sharingPreferences.fieldsForLevel(sharingLevel)
        
        if !allowedFields.contains(.name) { filtered.name = "" }
        if !allowedFields.contains(.title) { filtered.title = nil }
        if !allowedFields.contains(.company) { filtered.company = nil }
        if !allowedFields.contains(.email) { filtered.email = nil }
        if !allowedFields.contains(.phone) { filtered.phone = nil }
        if !allowedFields.contains(.profileImage) { filtered.profileImage = nil }
        if !allowedFields.contains(.skills) { filtered.skills = [] }
        
        return filtered
    }
}

/// Individual skill with categorization and proficiency levels
struct Skill: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var category: String
    var proficiencyLevel: ProficiencyLevel
    
    init(
        id: UUID = UUID(),
        name: String,
        category: String,
        proficiencyLevel: ProficiencyLevel = .intermediate
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.proficiencyLevel = proficiencyLevel
    }
}

/// Proficiency levels for skills
enum ProficiencyLevel: String, Codable, CaseIterable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case expert = "Expert"
    
    var displayOrder: Int {
        switch self {
        case .beginner: return 1
        case .intermediate: return 2
        case .advanced: return 3
        case .expert: return 4
        }
    }
}

/// Privacy controls for selective information sharing
struct SharingPreferences: Codable, Equatable {
    var publicFields: Set<BusinessCardField>
    var professionalFields: Set<BusinessCardField>
    var personalFields: Set<BusinessCardField>
    var allowForwarding: Bool
    var expirationDate: Date?
    
    init(
        publicFields: Set<BusinessCardField> = [.name, .title, .company],
        professionalFields: Set<BusinessCardField> = [.name, .title, .company, .email, .skills],
        personalFields: Set<BusinessCardField> = BusinessCardField.allCases.asSet(),
        allowForwarding: Bool = false,
        expirationDate: Date? = nil
    ) {
        self.publicFields = publicFields
        self.professionalFields = professionalFields
        self.personalFields = personalFields
        self.allowForwarding = allowForwarding
        self.expirationDate = expirationDate
    }
    
    /// Get allowed fields for a specific sharing level
    func fieldsForLevel(_ level: SharingLevel) -> Set<BusinessCardField> {
        switch level {
        case .`public`:
            return publicFields
        case .professional:
            return professionalFields
        case .personal:
            return personalFields
        }
    }
}

/// Available business card fields for privacy control
enum BusinessCardField: String, Codable, CaseIterable {
    case name = "name"
    case title = "title"
    case company = "company"
    case email = "email"
    case phone = "phone"
    case profileImage = "profileImage"
    case skills = "skills"
    
    var displayName: String {
        switch self {
        case .name: return "Name"
        case .title: return "Title"
        case .company: return "Company"
        case .email: return "Email"
        case .phone: return "Phone"
        case .profileImage: return "Profile Image"
        case .skills: return "Skills"
        }
    }
}

/// Sharing levels for privacy control
enum SharingLevel: String, Codable, CaseIterable {
    case `public` = "public"
    case professional = "professional"
    case personal = "personal"
    
    var displayName: String {
        switch self {
        case .`public`: return "Public"
        case .professional: return "Professional"
        case .personal: return "Personal"
        }
    }
}

// MARK: - Extensions

extension Array where Element == BusinessCardField {
    func asSet() -> Set<BusinessCardField> {
        return Set(self)
    }
}

extension BusinessCardField: Identifiable {
    var id: String { self.rawValue }
}

extension SharingLevel: Identifiable {
    var id: String { self.rawValue }
}