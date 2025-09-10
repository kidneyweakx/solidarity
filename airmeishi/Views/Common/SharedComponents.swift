//
//  SharedComponents.swift
//  airmeishi
//
//  Shared UI components used across multiple views
//

import SwiftUI

/// Simple contact info row for displaying contact information
struct ContactInfoRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
    }
}

/// Contact info row with action for ContactDetailView
struct ActionableContactInfoRow: View {
    let icon: String
    let title: String
    let value: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(value)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}



/// Metadata row for displaying non-interactive information
struct MetadataRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
    }
}

/// Skill chip for displaying skills with proficiency
struct SkillChip: View {
    let skill: Skill
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(skill.name)
                .font(.caption)
                .fontWeight(.medium)
            
            Text(skill.proficiencyLevel.rawValue)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.1))
        .foregroundColor(.blue)
        .cornerRadius(8)
    }
}

/// Tag chip for displaying and managing tags
struct TagChip: View {
    let tag: String
    let isEditing: Bool
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text("#\(tag)")
                .font(.caption)
            
            if isEditing {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.green.opacity(0.1))
        .foregroundColor(.green)
        .cornerRadius(8)
    }
}
#Preview {
    VStack(spacing: 16) {
        ContactInfoRow(
            icon: "envelope.fill",
            label: "Email",
            value: "test@example.com"
        )
        
        ActionableContactInfoRow(
            icon: "phone.fill",
            title: "Phone",
            value: "+1 (555) 123-4567"
        ) {
            print("Phone tapped")
        }
        
        MetadataRow(
            icon: "calendar",
            title: "Received on",
            value: "March 15, 2024"
        )
        
        SkillChip(skill: Skill(
            name: "Swift",
            category: "Programming",
            proficiencyLevel: .expert
        ))
        
        TagChip(tag: "colleague", isEditing: true) {
            print("Remove tag")
        }
    }
    .padding()
}