import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationView {
            Form {
                Section("Privacy") {
                    NavigationLink("Default Privacy Settings") {
                        Text("Privacy settings will be implemented in future tasks")
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}