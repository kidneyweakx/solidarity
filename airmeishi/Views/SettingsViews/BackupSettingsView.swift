//
//  BackupSettingsView.swift
//  airmeishi
//
//  Settings UI for enabling backups
//

import SwiftUI

struct BackupSettingsView: View {
    @StateObject private var backup = BackupManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            Section("Backup") {
                Toggle("Enable Backup", isOn: Binding(
                    get: { backup.settings.enabled },
                    set: { newVal in _ = backup.update { $0.enabled = newVal } }
                ))
                
                if backup.settings.enabled {
                    Toggle("iCloud", isOn: Binding(
                        get: { backup.settings.providers.contains(.iCloud) },
                        set: { on in
                            _ = backup.update { s in
                                if on { s.providers.insert(.iCloud) } else { s.providers.remove(.iCloud) }
                            }
                        }
                    ))
                    Toggle("Google Drive", isOn: Binding(
                        get: { backup.settings.providers.contains(.googleDrive) },
                        set: { on in
                            _ = backup.update { s in
                                if on { s.providers.insert(.googleDrive) } else { s.providers.remove(.googleDrive) }
                            }
                        }
                    ))
                }
            }
            
            Section("Actions") {
                Button("Back Up Now") {
                    let _ = backup.performBackupNow()
                }
                if let last = backup.settings.lastBackupAt {
                    Text("Last backup: \(last.formatted(date: .abbreviated, time: .shortened))")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Backup")
        .onAppear { backup.loadSettings() }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
    }
}

#Preview {
    NavigationView { BackupSettingsView() }
}


