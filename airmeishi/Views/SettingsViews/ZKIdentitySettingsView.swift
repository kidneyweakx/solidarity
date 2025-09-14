//
//  ZKIdentitySettingsView.swift
//  airmeishi
//
//  UI for generating identity, viewing commitment, and managing group membership.
//

import SwiftUI
import CryptoKit

struct ZKIdentitySettingsView: View {
    @StateObject private var idm = SemaphoreIdentityManager.shared
    @StateObject private var group = SemaphoreGroupManager.shared
    private let groupsAPI = GroupsService()
    @StateObject private var wallet = ReownWalletManager.shared

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

                sectionCard(title: "Group", systemImage: "person.3") {
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

                            Button { syncRootFromAPI() } label: { Label("Sync Root (API)", systemImage: "icloud.and.arrow.down") }
                                .buttonStyle(.bordered)
                                .disabled(isWorking || groupId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
        .onAppear { refresh() }
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

    private func syncRootFromAPI() {
        let gid = groupId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !gid.isEmpty else { return }
        isWorking = true
        Task {
            let result = await groupsAPI.getRoot(groupId: gid)
            DispatchQueue.main.async {
                switch result {
                case .success(let resp):
                    group.setMembers(group.members) // keep current; update root only
                    group.updateRoot(resp.zkRoot)
                    statusMessage = "Synced root"
                case .failure(let err):
                    errorMessage = err.localizedDescription
                    showErrorAlert = true
                }
                isWorking = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { statusMessage = nil }
            }
        }
    }

    private func addSelfViaAPI() {
        if identityCommitment.isEmpty, let id = idm.getIdentity() { identityCommitment = id.commitment }
        guard !identityCommitment.isEmpty else { return }
        let gid = groupId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !gid.isEmpty else { return }
        isWorking = true
        let commitment = identityCommitment
        let signaturePayload = "add|\(gid)|\(commitment)"
        guard let sigHex = signString(signaturePayload) else {
            errorMessage = "Failed to sign request"
            showErrorAlert = true
            isWorking = false
            return
        }
        let payload = AddMemberRequest(commitment: commitment, signature: sigHex)
        Task {
            let result = await groupsAPI.addMember(groupId: gid, payload: payload)
            DispatchQueue.main.async {
                switch result {
                case .success(let resp):
                    if !group.members.contains(commitment) { group.addMember(commitment) }
                    group.updateRoot(resp.newRoot)
                    statusMessage = "Uploaded membership"
                case .failure(let err):
                    errorMessage = err.localizedDescription
                    showErrorAlert = true
                }
                isWorking = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { statusMessage = nil }
            }
        }
    }

    private func revokeSelfViaAPI() {
        if identityCommitment.isEmpty, let id = idm.getIdentity() { identityCommitment = id.commitment }
        guard let idx = group.indexOf(identityCommitment) else { return }
        let gid = groupId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !gid.isEmpty else { return }
        isWorking = true
        // Derive a stable nullifier for this app context: hash(privateKey || groupId)
        guard let bundle = idm.getIdentity() else { isWorking = false; return }
        let nullifierHex = sha256Hex(bundle.privateKey + Data(gid.utf8))
        let signaturePayload = "revoke|\(gid)|\(idx)|\(nullifierHex)"
        guard let sigHex = signString(signaturePayload) else {
            errorMessage = "Failed to sign request"
            showErrorAlert = true
            isWorking = false
            return
        }
        let payload = RevokeMemberRequest(memberIndex: idx, nullifier: nullifierHex, signature: sigHex)
        Task {
            let result = await groupsAPI.revokeMember(groupId: gid, payload: payload)
            DispatchQueue.main.async {
                switch result {
                case .success(let resp):
                    group.removeMember(identityCommitment)
                    group.updateRoot(resp.newRoot)
                    statusMessage = "Revoked"
                case .failure(let err):
                    errorMessage = err.localizedDescription
                    showErrorAlert = true
                }
                isWorking = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { statusMessage = nil }
            }
        }
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

// MARK: - Wallet Header

extension ZKIdentitySettingsView {
    private var walletHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    Circle().fill(Color.accentColor.opacity(0.15)).frame(width: 44, height: 44)
                    Image(systemName: wallet.isConnected ? "checkmark.seal.fill" : "wallet.pass").foregroundColor(.accentColor)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(wallet.isConnected ? (wallet.displayName ?? "Wallet") : "Not Connected")
                        .font(.headline)
                    Text(wallet.accountAddress ?? "—")
                        .font(.footnote.monospaced())
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                Spacer()
                if wallet.isConnected {
                    Menu {
                        Button("Disconnect", role: .destructive) { wallet.disconnect() }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
            }
            HStack(spacing: 10) {
                if wallet.isConnected {
                    Button { signSemaphoreData() } label: {
                        HStack(spacing: 8) { Image(systemName: "signature"); Text("Sign Semaphore").fontWeight(.semibold) }
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(AccentGradientButtonStyle())
                } else {
                    Button { wallet.connect() } label: {
                        HStack(spacing: 8) { Image(systemName: "link.badge.plus"); Text("Connect Wallet").fontWeight(.semibold) }
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(AccentGradientButtonStyle())
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(uiColor: .secondarySystemBackground)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.secondary.opacity(0.15)))
    }
    
    private func signSemaphoreData() {
        // Ensure commitment present
        if identityCommitment.isEmpty, let id = idm.getIdentity() { identityCommitment = id.commitment }
        guard !identityCommitment.isEmpty else {
            errorMessage = "No identity commitment. Generate first."
            showErrorAlert = true
            return
        }
        let gid = groupId.trimmingCharacters(in: .whitespacesAndNewlines)
        let payload: [String: String] = [
            "type": "semaphore-sign",
            "commitment": identityCommitment,
            "groupId": gid,
            "merkleRoot": group.merkleRoot ?? "",
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        if let data = try? JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys]),
           let toSign = String(data: data, encoding: .utf8),
           let sig = wallet.signMessage(toSign) {
            print("====== [WalletSign] Semaphore Signing Request ======")
            print("Address: \(wallet.accountAddress ?? "-")")
            print("DisplayName: \(wallet.displayName ?? "-")")
            print("Commitment: \(identityCommitment)")
            print("GroupId: \(gid)")
            print("MerkleRoot: \(group.merkleRoot ?? "")")
            print("Payload JSON: \(toSign)")
            print("Signature (hex, \(sig.count) chars): \(sig)")
            print("===================================================")
            statusMessage = "Signed (semaphore): \(sig.prefix(10))…"
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { statusMessage = nil }
        } else {
            errorMessage = "Failed to sign"
            showErrorAlert = true
        }
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


