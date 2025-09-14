//
//  PrivacySettingsView.swift
//  airmeishi
//
//  Privacy controls for selective information sharing
//

import SwiftUI

struct PrivacySettingsView: View {
    @Binding var sharingPreferences: SharingPreferences
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            // ZK toggle
            Section {
                Toggle("Enable ZK Selective Disclosure", isOn: $sharingPreferences.useZK)
                Text("When enabled, QR and proximity shares include proofs and only reveal allowed fields per level.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("Zero-Knowledge")
            }
            
            // Cool level list
            Section("Privacy Levels") {
                VStack(spacing: 12) {
                    LevelCardView(
                        title: "Public",
                        subtitle: "Visible to anyone scanning your QR",
                        icon: "globe",
                        fields: sharingPreferences.publicFields,
                        useZK: sharingPreferences.useZK
                    )
                    LevelCardView(
                        title: "Professional",
                        subtitle: "For business contexts",
                        icon: "briefcase",
                        fields: sharingPreferences.professionalFields,
                        useZK: sharingPreferences.useZK
                    )
                    LevelCardView(
                        title: "Personal",
                        subtitle: "Full info for trusted contacts",
                        icon: "person.crop.circle",
                        fields: sharingPreferences.personalFields,
                        useZK: sharingPreferences.useZK
                    )
                }
                .listRowInsets(EdgeInsets())
            }
            
            Section("Additional Settings") {
                Toggle("Allow Forwarding", isOn: $sharingPreferences.allowForwarding)
                
                DatePicker(
                    "Expiration Date",
                    selection: Binding(
                        get: { sharingPreferences.expirationDate ?? Date().addingTimeInterval(86400 * 30) },
                        set: { sharingPreferences.expirationDate = $0 }
                    ),
                    displayedComponents: [.date]
                )
                
                Button("Remove Expiration") {
                    sharingPreferences.expirationDate = nil
                }
                .foregroundColor(.red)
                .disabled(sharingPreferences.expirationDate == nil)
            }
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Privacy Levels:")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Public")
                            .fontWeight(.medium)
                        Text("Information visible to anyone who scans your QR code")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Professional")
                            .fontWeight(.medium)
                        Text("Information shared in business contexts")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Personal")
                            .fontWeight(.medium)
                        Text("Full information for trusted contacts")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("Guidelines")
            }
        }
        .navigationTitle("Privacy Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
    
    private func updateField(_ field: BusinessCardField, enabled: Bool, for level: SharingLevel) {
        switch level {
        case .public:
            if enabled {
                sharingPreferences.publicFields.insert(field)
            } else {
                sharingPreferences.publicFields.remove(field)
            }
        case .professional:
            if enabled {
                sharingPreferences.professionalFields.insert(field)
            } else {
                sharingPreferences.professionalFields.remove(field)
            }
        case .personal:
            if enabled {
                sharingPreferences.personalFields.insert(field)
            } else {
                sharingPreferences.personalFields.remove(field)
            }
        }
    }
}

#Preview {
    NavigationView {
        PrivacySettingsView(sharingPreferences: .constant(SharingPreferences()))
    }
}

// MARK: - Components
private struct LevelCardView: View {
    let title: String
    let subtitle: String
    let icon: String
    let fields: Set<BusinessCardField>
    let useZK: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.accentColor)
                    .frame(width: 32, height: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if useZK {
                    HStack(spacing: 6) {
                        Image(systemName: "shield.checkerboard")
                            .foregroundColor(.green)
                        Text("ZK")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
            }
            
            // Field summary row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(fields).sorted { $0.displayName < $1.displayName }) { field in
                        FieldPill(text: field.displayName)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color(UIColor.secondarySystemBackground)))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color(UIColor.separator).opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal)
    }
}

private struct FieldPill: View, Identifiable {
    let id = UUID()
    let text: String
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.accentColor.opacity(0.9))
                .frame(width: 6, height: 6)
            Text(text)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule().fill(Color(UIColor.tertiarySystemFill))
        )
    }
}