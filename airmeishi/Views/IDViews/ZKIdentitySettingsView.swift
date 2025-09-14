//
//  ZKIdentitySettingsView.swift
//  airmeishi
//
//  UI for generating identity, viewing commitment, and managing group membership.
//

import SwiftUI
import CryptoKit
import BigInt
import Web3
import Web3Auth

struct ZKIdentitySettingsView: View {
    @StateObject private var idm = SemaphoreIdentityManager.shared
    @StateObject private var group = SemaphoreGroupManager.shared
    @StateObject private var web3Auth = Web3AuthManager.shared
    @State private var web3RPC: Web3RPC?
    

    @State private var identityCommitment: String = ""
    @State private var groupId: String = "engineering"
    @State private var message: String = "Hello from airmeishi"
    @State private var scope: String = "public"
    @State private var generatedProof: String?
    @Environment(\.dismiss) private var dismiss
    @State private var isWorking: Bool = false
    @State private var statusMessage: String?
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String?
    @State private var emailInput: String = ""
    @State private var showEmailLogin: Bool = false
    
    // ENS Signing states
    @State private var ensDomain: String = ""
    @State private var ensSignature: String = ""
    @State private var isSigningENS: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                web3AuthHeader
                sectionCard(title: "Identity", systemImage: "person.text.rectangle") {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .top) {
                            Text("Commitment")
                            Spacer()
                            Text(identityCommitment.isEmpty ? "—" : identityCommitment)
                                .font(.footnote.monospaced())
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                                .multilineTextAlignment(.trailing)
                                .textSelection(.enabled)
                        }
                        HStack {
                            Button {
                                loadOrCreate()
                            } label: {
                                Label("Generate / Load", systemImage: "key.viewfinder")
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(isWorking)

                            if !identityCommitment.isEmpty {
                                Button {
                                    #if canImport(UIKit)
                                    UIPasteboard.general.string = identityCommitment
                                    #endif
                                    statusMessage = "Copied"
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { statusMessage = nil }
                                } label: {
                                    Label("Copy", systemImage: "doc.on.doc")
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }

                sectionCard(title: "Group (Local Demo)", systemImage: "person.3") {
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("Group ID", text: $groupId)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .textFieldStyle(.roundedBorder)

                        HStack(alignment: .top) {
                            Text("Merkle Root")
                            Spacer()
                            Text(group.merkleRoot ?? "—")
                                .font(.footnote.monospaced())
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                                .multilineTextAlignment(.trailing)
                                .textSelection(.enabled)
                        }

                        HStack(spacing: 10) {
                            Button {
                                addSelfViaAPI()
                            } label: {
                                Label("Upload My Membership", systemImage: "arrow.up.circle.fill")
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(isWorking || identityCommitment.isEmpty || groupId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                            Button(role: .destructive) {
                                revokeSelfViaAPI()
                            } label: {
                                Label("Revoke Me", systemImage: "xmark.seal.fill")
                            }
                            .buttonStyle(.bordered)
                            .disabled(isWorking || identityCommitment.isEmpty || group.indexOf(identityCommitment) == nil)
                        }

                        HStack(spacing: 10) {
                            Button {
                                group.recomputeRoot()
                            } label: { Label("Recompute", systemImage: "arrow.clockwise") }
                            .buttonStyle(.bordered)

                            // Old API removed; keep local recompute only
                            EmptyView()
                        }

                        if !group.members.isEmpty {
                            NavigationLink { MembersList(members: group.members) } label: {
                                HStack {
                                    Label("View Members", systemImage: "list.bullet.rectangle.portrait")
                                    Spacer()
                                    Text("\(group.members.count)")
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(Color.secondary.opacity(0.15)))
                                }
                            }
                        }
                    }
                }

                sectionCard(title: "Proof (Demo)", systemImage: "checkmark.seal") {
                    VStack(alignment: .leading, spacing: 10) {
                        TextField("Message", text: $message)
                            .textFieldStyle(.roundedBorder)
                        TextField("Scope", text: $scope)
                            .textFieldStyle(.roundedBorder)
                        Button { generateProof() } label: { Label("Generate Proof", systemImage: "wand.and.stars") }
                            .buttonStyle(.borderedProminent)
                            .disabled(isWorking)
                        if let proof = generatedProof {
                            ScrollView { Text(proof).font(.footnote).textSelection(.enabled) }
                                .frame(minHeight: 100)
                        }
                    }
                }

                sectionCard(title: "ENS Signing", systemImage: "globe") {
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("ENS Domain (e.g., mygroup.eth)", text: $ensDomain)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .textFieldStyle(.roundedBorder)
                        
                        HStack(spacing: 10) {
                            Button {
                                signENS()
                            } label: {
                                HStack {
                                    if isSigningENS {
                                        ProgressView()
                                            .controlSize(.small)
                                    }
                                    Label("Sign", systemImage: "pencil.and.outline")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(ensDomain.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSigningENS || !web3Auth.isLoggedIn)
                        }
                        
                        if !ensSignature.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("ENS Signature:")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Button {
                                        #if canImport(UIKit)
                                        UIPasteboard.general.string = ensSignature
                                        #endif
                                        statusMessage = "Signature copied"
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { statusMessage = nil }
                                    } label: {
                                        Label("Copy", systemImage: "doc.on.doc")
                                    }
                                    .buttonStyle(.bordered)
                                }
                                
                                ScrollView {
                                    Text(ensSignature)
                                        .font(.footnote.monospaced())
                                        .textSelection(.enabled)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .frame(minHeight: 60)
                                .padding(8)
                                .background(Color(uiColor: .tertiarySystemBackground))
                                .cornerRadius(8)
                            }
                        }
                    }
                }

                sectionCard(title: "Backup", systemImage: "externaldrive.fill.badge.icloud") {
                    NavigationLink { BackupSettingsView() } label: {
                        Label("Backup Settings", systemImage: "gear")
                    }
                    .buttonStyle(.bordered)
                }

                if let status = statusMessage {
                    Text(status)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .transition(.opacity)
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
        }
        .navigationTitle("ZK Identity")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { dismiss() } } }
        .onAppear {
            refresh()
        }
        .alert("Error", isPresented: $showErrorAlert) { Button("OK", role: .cancel) {} } message: { Text(errorMessage ?? "Unknown error") }
        .hideKeyboardAccessory()
    }

    private func refresh() {
        if let id = idm.getIdentity() { identityCommitment = id.commitment }
    }

    private func loadOrCreate() { if let bundle = try? idm.loadOrCreateIdentity() { identityCommitment = bundle.commitment } }

    private func addSelfToGroup() {
        if identityCommitment.isEmpty, let id = idm.getIdentity() { identityCommitment = id.commitment }
        guard !identityCommitment.isEmpty else { return }
        group.addMember(identityCommitment)
    }

    private func generateProof() {
        guard !group.members.isEmpty else { return }
        do {
            let proof = try idm.generateProof(groupCommitments: group.members, message: message, scope: scope, merkleDepth: 16)
            generatedProof = proof
        } catch {
            generatedProof = "Failed: \(error.localizedDescription)"
        }
    }

    // MARK: - API actions

    // Old API sync removed

    private func addSelfViaAPI() {
        // Old API removed; keep local add only
        if identityCommitment.isEmpty, let id = idm.getIdentity() { identityCommitment = id.commitment }
        guard !identityCommitment.isEmpty else { return }
        let commitment = identityCommitment
        if !group.members.contains(commitment) { group.addMember(commitment) }
        statusMessage = "Added locally"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { statusMessage = nil }
    }

    private func revokeSelfViaAPI() {
        // Old API removed; keep local revoke only
        if identityCommitment.isEmpty, let id = idm.getIdentity() { identityCommitment = id.commitment }
        guard group.indexOf(identityCommitment) != nil else { return }
        group.removeMember(identityCommitment)
        statusMessage = "Revoked locally"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { statusMessage = nil }
    }

    // MARK: - Helpers (local)

    private func sha256Hex(_ data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private func signString(_ text: String) -> String? {
        let km = KeyManager.shared
        let result = km.getSigningKeyPair()
        switch result {
        case .success(let pair):
            let data = Data(text.utf8)
            do {
                let sig = try pair.privateKey.signature(for: data)
                return sig.rawRepresentation.map { String(format: "%02x", $0) }.joined()
            } catch {
                return nil
            }
        case .failure:
            return nil
        }
    }
    
    // MARK: - ENS Functions
    
    // ENS resolution via API removed
    
    private func signENS() {
        guard !ensDomain.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard web3Auth.isLoggedIn, let user = web3Auth.user else {
            errorMessage = "Please login with Web3Auth first"
            showErrorAlert = true
            return
        }
        
        isSigningENS = true
        
        // Initialize Web3RPC if not already done
        if web3RPC == nil {
            web3RPC = Web3RPC(user: user)
        }
        
        guard let rpc = web3RPC else {
            isSigningENS = false
            errorMessage = "Failed to initialize Web3RPC"
            showErrorAlert = true
            return
        }
        
        Task {
            do {
                // Create a message to sign that includes the ENS domain and current timestamp
                let timestamp = Int(Date().timeIntervalSince1970)
                let messageToSign = "I am the owner of \(ensDomain) at \(timestamp)"
                
                // Sign the message using Web3RPC
                let signature = try rpc.signMessage(message: messageToSign)
                
                DispatchQueue.main.async {
                    self.ensSignature = signature
                    self.isSigningENS = false
                    self.statusMessage = "ENS domain signed successfully"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { self.statusMessage = nil }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isSigningENS = false
                    self.errorMessage = "Failed to sign ENS domain: \(error.localizedDescription)"
                    self.showErrorAlert = true
                }
            }
        }
    }

    private struct MembersList: View {
        let members: [String]
        var body: some View {
            List(members, id: \.self) { m in
                Text(m).font(.footnote).textSelection(.enabled)
            }
            .navigationTitle("Group Members")
        }
    }

    // MARK: - Styled section helper
    @ViewBuilder
    private func sectionCard<Content: View>(title: String, systemImage: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.headline)
            }
            content()
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(uiColor: .secondarySystemBackground)))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.secondary.opacity(0.15))
        )
    }
}

#Preview {
    NavigationView { ZKIdentitySettingsView() }
}

// MARK: - Web3Auth Header

extension ZKIdentitySettingsView {
    private var web3AuthHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Wallet Login")
                .font(.headline)

            if web3Auth.isLoading {
                HStack {
                    ProgressView().controlSize(.small)
                    Text("Loading...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if web3Auth.isLoggedIn {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Signed in")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    if let addr = web3Auth.address {
                        Text(addr)
                            .font(.footnote.monospaced())
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                    Button("Logout", role: .destructive) { web3Auth.logout() }
                        .buttonStyle(.bordered)
                }
            } else {
                Button { web3Auth.login() } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "apple.logo")
                        Text("Sign In with Apple").fontWeight(.semibold)
                    }
                }
                .buttonStyle(AccentGradientButtonStyle())
                .disabled(web3Auth.isLoading)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(uiColor: .secondarySystemBackground)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.secondary.opacity(0.15)))
    }
}

// MARK: - AccentGradientButtonStyle

private struct AccentGradientButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(colors: [Color.purple.opacity(0.95), Color.blue.opacity(0.9)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            )
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.2)))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}


