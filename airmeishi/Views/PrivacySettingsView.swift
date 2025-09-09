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
            Section {
                Text("Control what information is shared at different privacy levels. Recipients will only see the fields you've enabled for their sharing level.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ForEach(SharingLevel.allCases, id: \.self) { level in
                Section(level.displayName) {
                    ForEach(BusinessCardField.allCases, id: \.self) { field in
                        Toggle(field.displayName, isOn: Binding(
                            get: {
                                sharingPreferences.fieldsForLevel(level).contains(field)
                            },
                            set: { isEnabled in
                                updateField(field, enabled: isEnabled, for: level)
                            }
                        ))
                    }
                }
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