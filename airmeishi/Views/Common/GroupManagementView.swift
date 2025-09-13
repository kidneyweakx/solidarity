//
//  GroupManagementView.swift
//  airmeishi
//
//  Manage group membership: view root, add/remove members, join via code/url.
//

import SwiftUI

struct GroupManagementView: View {
    @StateObject private var group = SemaphoreGroupManager.shared
    @State private var newMemberCommitment: String = ""
    @State private var joinCode: String = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("Merkle Root") {
                Text(group.merkleRoot ?? "—").font(.footnote).textSelection(.enabled)
                HStack {
                    Button("Recompute") { group.recomputeRoot() }
                    Spacer()
                    Button("Sync") { group.syncRootFromNetwork { _ in } }
                }
            }

            Section("Members (\(group.members.count))") {
                if group.members.isEmpty {
                    Text("No members yet").foregroundColor(.secondary)
                } else {
                    List(group.members, id: \.self) { m in
                        HStack {
                            Text(m).font(.footnote).lineLimit(1)
                            Spacer()
                            Button(role: .destructive) { group.removeMember(m) } label: { Image(systemName: "trash") }
                        }
                    }
                    .frame(minHeight: 120)
                }
            }

            Section("Add Member") {
                TextField("Commitment", text: $newMemberCommitment)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button("Add to Group") {
                    let c = newMemberCommitment.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !c.isEmpty else { return }
                    group.addMember(c)
                    newMemberCommitment = ""
                }
                .disabled(newMemberCommitment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            Section("Join Group") {
                TextField("Invite code or URL (placeholder)", text: $joinCode)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button("Join") {
                    // TODO: Implement real join logic with API
                }
                .disabled(joinCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .navigationTitle("Group Management")
        .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { dismiss() } } }
    }
}

#Preview {
    NavigationView { GroupManagementView() }
}


