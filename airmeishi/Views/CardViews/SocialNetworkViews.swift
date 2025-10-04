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

    @State private var localPlatform: SocialPlatform
    @State private var localUsername: String
    @State private var localUrl: String

    init(platform: Binding<SocialPlatform>, username: Binding<String>, url: Binding<String>, onSave: @escaping (SocialNetwork) -> Void) {

        self._platform = platform
        self._username = username
        self._url = url
        self.onSave = onSave
        self._localPlatform = State(initialValue: platform.wrappedValue)
        self._localUsername = State(initialValue: username.wrappedValue)
        self._localUrl = State(initialValue: url.wrappedValue)

    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker("Platform", selection: $localPlatform) {
                        ForEach(SocialPlatform.allCases, id: \.self) { platform in
                            Text(platform.rawValue).tag(platform)
                        }
                    }

                    TextField("Username", text: $localUsername)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    TextField("URL (optional)", text: $localUrl)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
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
            .onAppear {
            }
        }
        .onAppear {
        }
    }
    
    private var isFormValid: Bool {
        !localUsername.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func saveSocialNetwork() {
        let trimmedUsername = localUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUrl = localUrl.trimmingCharacters(in: .whitespacesAndNewlines)

        // Update bindings
        platform = localPlatform
        username = trimmedUsername
        url = trimmedUrl

        let social = SocialNetwork(
            platform: localPlatform,
            username: trimmedUsername,
            url: trimmedUrl.isEmpty ? nil : trimmedUrl
        )

        onSave(social)
        dismiss()
    }
}


