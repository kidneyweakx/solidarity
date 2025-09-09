//
//  SkillFormView.swift
//  airmeishi
//
//  Form for adding and editing skills with categorization and proficiency levels
//

import SwiftUI

struct SkillFormView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var skillName: String
    @Binding var skillCategory: String
    @Binding var proficiencyLevel: ProficiencyLevel
    
    @State private var showingCustomCategory = false
    @State private var customCategory = ""
    
    let onSave: (Skill) -> Void
    
    // Common skill categories
    private let commonCategories = [
        "Programming",
        "Design",
        "Marketing",
        "Sales",
        "Management",
        "Finance",
        "Operations",
        "Engineering",
        "Data Science",
        "Product",
        "Customer Service",
        "Human Resources",
        "Legal",
        "Consulting",
        "Education",
        "Healthcare",
        "Research",
        "Writing",
        "Languages",
        "Other"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Skill Details") {
                    TextField("Skill Name", text: $skillName)
                        .textInputAutocapitalization(.words)
                    
                    if showingCustomCategory {
                        TextField("Custom Category", text: $customCategory)
                            .textInputAutocapitalization(.words)
                            .onChange(of: customCategory) { _, newValue in
                                skillCategory = newValue
                            }
                    } else {
                        Picker("Category", selection: $skillCategory) {
                            ForEach(commonCategories, id: \.self) { category in
                                Text(category).tag(category)
                            }
                        }
                        .onChange(of: skillCategory) { _, newValue in
                            if newValue == "Other" {
                                showingCustomCategory = true
                                customCategory = ""
                                skillCategory = ""
                            }
                        }
                    }
                    
                    if showingCustomCategory {
                        Button("Use Predefined Categories") {
                            showingCustomCategory = false
                            skillCategory = commonCategories.first ?? ""
                        }
                        .foregroundColor(.blue)
                    }
                    
                    Picker("Proficiency Level", selection: $proficiencyLevel) {
                        ForEach(ProficiencyLevel.allCases, id: \.self) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Proficiency Levels:")
                            .font(.headline)
                        
                        ForEach(ProficiencyLevel.allCases, id: \.self) { level in
                            HStack {
                                Text(level.rawValue)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                                Text(proficiencyDescription(for: level))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Guidelines")
                } footer: {
                    Text("Choose the level that best represents your current expertise")
                }
            }
            .navigationTitle("Add Skill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        saveSkill()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !skillName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !skillCategory.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func saveSkill() {
        let trimmedName = skillName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCategory = skillCategory.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let skill = Skill(
            name: trimmedName,
            category: trimmedCategory,
            proficiencyLevel: proficiencyLevel
        )
        
        onSave(skill)
        dismiss()
    }
    
    private func proficiencyDescription(for level: ProficiencyLevel) -> String {
        switch level {
        case .beginner:
            return "Learning the basics"
        case .intermediate:
            return "Comfortable with fundamentals"
        case .advanced:
            return "Highly skilled and experienced"
        case .expert:
            return "Industry leader and mentor"
        }
    }
}

#Preview {
    SkillFormView(
        skillName: .constant(""),
        skillCategory: .constant("Programming"),
        proficiencyLevel: .constant(.intermediate)
    ) { _ in }
}