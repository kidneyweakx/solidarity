//
//  SkillFormView.swift
//  airmeishi
//
//  Simplified skill form - now only used for advanced features
//

import SwiftUI

struct SkillFormView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var skillName: String
    @Binding var skillCategory: String
    @Binding var proficiencyLevel: ProficiencyLevel
    
    let onSave: (Skill) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section("Skill Details") {
                    TextField("Skill Name", text: $skillName)
                        .textInputAutocapitalization(.words)
                    
                    TextField("Category", text: $skillCategory)
                        .textInputAutocapitalization(.words)
                    
                    Picker("Proficiency Level", selection: $proficiencyLevel) {
                        ForEach(ProficiencyLevel.allCases, id: \.self) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
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
        .hideKeyboardAccessory()
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
}

#Preview {
    SkillFormView(
        skillName: .constant(""),
        skillCategory: .constant("Programming"),
        proficiencyLevel: .constant(.intermediate)
    ) { _ in }
}