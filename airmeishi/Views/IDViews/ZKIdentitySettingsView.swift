//
//  ZKIdentitySettingsView.swift
//  airmeishi
//
//  UI for generating identity, viewing commitment, and managing group membership.
//

import SwiftUI
import CryptoKit
import BigInt
import Foundation

struct ZKIdentitySettingsView: View {
    @StateObject private var idm = SemaphoreIdentityManager.shared
    @StateObject private var group = SemaphoreGroupManager.shared
    @StateObject private var wallet = CoinbaseWalletService.shared
    

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
    
    // ENS write states
    @State private var ensDomain: String = ""
    @State private var ensKey: String = "url"
    @State private var ensValue: String = "https://example.com"
    @State private var resolverAddress: String = ""
    @State private var isSendingENSTx: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                walletHeader
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

                sectionCard(title: "ENS Write (Sepolia)", systemImage: "globe") {
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("ENS Domain (e.g., mygroup.eth)", text: $ensDomain)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .textFieldStyle(.roundedBorder)
                        TextField("Key (e.g., url, avatar)", text: $ensKey)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .textFieldStyle(.roundedBorder)
                        TextField("Value", text: $ensValue)
                            .textFieldStyle(.roundedBorder)
                        TextField("Resolver Address (0x... on Sepolia)", text: $resolverAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .textFieldStyle(.roundedBorder)
                        
                        HStack(spacing: 10) {
                            Button {
                                sendENSTransaction()
                            } label: {
                                HStack {
                                    if isSendingENSTx {
                                        ProgressView()
                                            .controlSize(.small)
                                    }
                                    Label("Send", systemImage: "paperplane")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(ensDomain.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || resolverAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSendingENSTx || !wallet.isConnected)
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
    
    // MARK: - ENS Functions (send transaction via Coinbase Wallet)
    private func sendENSTransaction() {
        guard !ensDomain.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard !resolverAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isSendingENSTx = true
        wallet.addSepoliaChainIfNeeded()
        wallet.switchToSepoliaIfNeeded()
        CoinbaseWalletService.shared.sendENSSetText(domain: ensDomain, key: ensKey, value: ensValue, resolverAddress: resolverAddress)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isSendingENSTx = false
            if let tx = wallet.lastTransactionHash {
                self.statusMessage = "ENS tx sent: \(tx)"
            } else if let err = wallet.lastErrorMessage {
                self.errorMessage = err
                self.showErrorAlert = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { self.statusMessage = nil }
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

// MARK: - Wallet Header (Coinbase Wallet)

extension ZKIdentitySettingsView {
    private var walletHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Wallet Login")
                .font(.headline)
            if wallet.isConnected, let addr = wallet.selectedAddress {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Connected")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(addr)
                        .font(.footnote.monospaced())
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            } else {
                Button {
                    print("🔗 [Wallet] Starting connection process...")
                    print("🔗 [Wallet] isRequestInFlight: \(wallet.isRequestInFlight)")
                    print("🔗 [Wallet] isConnected: \(wallet.isConnected)")
                    wallet.connectAndRequestAccounts()
                } label: {
                    Label("Connect Coinbase Wallet", systemImage: "link")
                }
                .buttonStyle(AccentGradientButtonStyle())
            }
            
            // Debug info
            VStack(alignment: .leading, spacing: 4) {
                Text("Debug Info")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Connected: \(wallet.isConnected ? "Yes" : "No")")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("Request In Flight: \(wallet.isRequestInFlight ? "Yes" : "No")")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                if let error = wallet.lastErrorMessage {
                    Text("Last Error: \(error)")
                        .font(.caption2)
                        .foregroundColor(.red)
                        .lineLimit(2)
                }
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


