//
//  ZKIdentitySettingsView.swift
//  airmeishi
//
//  UI for generating identity, viewing commitment, and managing group membership.
//

import SwiftUI

struct ZKIdentitySettingsView: View {
    @StateObject private var idm = SemaphoreIdentityManager.shared
    @StateObject private var group = SemaphoreGroupManager.shared

    @State private var identityCommitment: String = ""
    @State private var message: String = "Hello from airmeishi"
    @State private var scope: String = "public"
    @State private var generatedProof: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("Identity") {
                HStack {
                    Text("Commitment")
                    Spacer()
                    Text(identityCommitment.isEmpty ? "—" : identityCommitment)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.trailing)
                }
                Button("Generate / Load Identity") { loadOrCreate() }
            }

            Section("Group") {
                HStack {
                    Text("Merkle Root")
                    Spacer()
                    Text(group.merkleRoot ?? "—")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.trailing)
                }
                Button("Add My Commitment To Group") { addSelfToGroup() }
                Button("Recompute Root") { group.recomputeRoot() }
                Button("Sync Root (API/Chain)") { group.syncRootFromNetwork { _ in } }
                Button("Push Updates (API/Chain)") { group.pushUpdatesToNetwork { _ in } }
                if !group.members.isEmpty {
                    NavigationLink("View Members (\(group.members.count))") {
                        MembersList(members: group.members)
                    }
                }
            }

            Section("Proof (Demo)") {
                TextField("Message", text: $message)
                TextField("Scope", text: $scope)
                Button("Generate Proof") { generateProof() }
                if let proof = generatedProof {
                    ScrollView { Text(proof).font(.footnote).textSelection(.enabled) }
                        .frame(minHeight: 100)
                }
            }
        }
        .navigationTitle("ZK Identity")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { dismiss() } } }
        .onAppear { refresh()
        }
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

    private struct MembersList: View {
        let members: [String]
        var body: some View {
            List(members, id: \.self) { m in
                Text(m).font(.footnote).textSelection(.enabled)
            }
            .navigationTitle("Group Members")
        }
    }
}

#Preview {
    NavigationView { ZKIdentitySettingsView() }
}


