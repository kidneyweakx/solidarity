//
//  SocialNetworkViews.swift
//  airmeishi
//
//  Extracted subviews for social network management in the card form.
//

import SwiftUI

struct SocialNetworkRowView: View {
    let social: SocialNetwork
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: social.platform.icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(social.platform.rawValue)
                    .font(.body)
                
                Text(social.username)
                    .font(.caption)
                    .foregroundColor(.secondary)
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

struct SocialNetworkFormView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var platform: SocialPlatform
    @Binding var username: String
    @Binding var url: String
    
    let onSave: (SocialNetwork) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker("Platform", selection: $platform) {
                        ForEach(SocialPlatform.allCases, id: \.self) { platform in
                            Text(platform.rawValue).tag(platform)
                        }
                    }
                    
                    TextField("Username", text: $username)
                        .textInputAutocapitalization(.never)
                    
                    TextField("URL (optional)", text: $url)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                } header: {
                    Text("Social Network Details")
                }
            }
            .navigationTitle("Add Social Network")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        saveSocialNetwork()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func saveSocialNetwork() {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUrl = url.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let social = SocialNetwork(
            platform: platform,
            username: trimmedUsername,
            url: trimmedUrl.isEmpty ? nil : trimmedUrl
        )
        
        onSave(social)
        dismiss()
    }
}


