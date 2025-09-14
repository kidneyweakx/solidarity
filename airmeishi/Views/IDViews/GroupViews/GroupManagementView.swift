//
//  GroupManagementView.swift
//  airmeishi
//
//  Manage group membership: view root, add/remove members, join via code/url.
//

import SwiftUI
import UIKit

struct GroupManagementView: View {
    @StateObject private var group = SemaphoreGroupManager.shared
    @State private var newMemberCommitment: String = ""
    @State private var joinCode: String = ""
    @State private var ensName: String = ""
    @State private var ensResolvedAddress: String? = nil
    @State private var isResolvingENS: Bool = false
    @State private var isFetchingRoot: Bool = false
    @State private var joinQRImage: UIImage? = nil
    @State private var activeSheet: SheetType? = nil
    @Environment(\.dismiss) private var dismiss

    private enum SheetType: String, Identifiable {
        case root, add, revoke, invite
        var id: String { rawValue }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                NodeRow(icon: "checkmark.seal", title: "Root") { activeSheet = .root }
                Connector()
                NodeRow(icon: "person.badge.plus", title: "Add User") { activeSheet = .add }
                Connector()
                NodeRow(icon: "person.badge.minus", title: "Revoke User") { activeSheet = .revoke }
                Connector()
                NodeRow(icon: "qrcode", title: "Invite via QR") { activeSheet = .invite }
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 20)
        }
        .navigationTitle("Group Management")
        .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { dismiss() } } }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .root:
                RootSheet
            case .add:
                AddMemberSheet
            case .revoke:
                RevokeMemberSheet
            case .invite:
                InviteSheet
            }
        }
    }

    // MARK: - Helpers

    private func resolveENS() {
        guard !ensName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isResolvingENS = true
        Task {
            let res = await ENSService().resolve(name: ensName)
            DispatchQueue.main.async {
                self.isResolvingENS = false
                switch res {
                case .success(let payload):
                    self.ensResolvedAddress = payload.address
                case .failure:
                    self.ensResolvedAddress = nil
                }
            }
        }
    }

    private func fetchRootViaENS() {
        guard !ensName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isFetchingRoot = true
        Task {
            let res = await GroupsService().getRoot(groupId: ensName)
            DispatchQueue.main.async {
                self.isFetchingRoot = false
                if case .success(let payload) = res {
                    self.group.updateRoot(payload.zkRoot)
                }
            }
        }
    }

    private func copyRoot() {
        if let root = group.merkleRoot { UIPasteboard.general.string = root }
    }

    private func makeJoinURL() -> String {
        let ens = ensName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !ens.isEmpty else { return "" }
        var comps = URLComponents(string: "https://airmeishi.app")
        comps?.path = "/group/join"
        var items: [URLQueryItem] = [URLQueryItem(name: "ens", value: ens)]
        if let root = group.merkleRoot { items.append(URLQueryItem(name: "root", value: root)) }
        comps?.queryItems = items
        return comps?.url?.absoluteString ?? ""
    }

    private func generateJoinQR() {
        let url = makeJoinURL()
        guard !url.isEmpty else { return }
        let result = QRCodeManager.shared.generateQRCode(from: url)
        if case .success(let image) = result { self.joinQRImage = image }
    }

    // MARK: - Sheets

    private var RootSheet: some View {
        NavigationView {
            Form {
                if !group.allGroups.isEmpty {
                    Section("Your Groups") {
                        ForEach(group.allGroups) { g in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(g.name).font(.headline)
                                    Text(g.root ?? "—").font(.caption).foregroundColor(.secondary).lineLimit(1)
                                }
                                Spacer()
                                if group.selectedGroupId == g.id {
                                    Image(systemName: "checkmark.circle.fill").foregroundColor(.accentColor)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { group.selectGroup(g.id) }
                        }
                    }
                }
                Section("Merkle Root") {
                    Text(group.merkleRoot ?? "—").font(.footnote).textSelection(.enabled)
                    HStack {
                        Button("Recompute") { group.recomputeRoot() }
                        Spacer()
                        Button("Copy") { copyRoot() }.disabled(group.merkleRoot == nil)
                    }
                    HStack {
                        if isFetchingRoot { ProgressView().controlSize(.mini) }
                        Button("Sync") { group.syncRootFromNetwork { _ in } }
                        Spacer()
                    }
                }
                Section("ENS Anchor") {
                    HStack {
                        TextField("mygroup.eth", text: $ensName)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        if isResolvingENS { ProgressView().controlSize(.mini) }
                        Button("Resolve") { resolveENS() }
                            .disabled(ensName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isResolvingENS)
                    }
                    if let addr = ensResolvedAddress, !addr.isEmpty {
                        HStack { Text("Address:").foregroundColor(.secondary); Text(addr).font(.footnote).textSelection(.enabled); Spacer() }
                    }
                    HStack {
                        if isFetchingRoot { ProgressView().controlSize(.mini) }
                        Button("Fetch Root via ENS") { fetchRootViaENS() }
                            .disabled(ensName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isFetchingRoot)
                    }
                }
                Section("Your Identity") {
                    let bundle = SemaphoreIdentityManager.shared.getIdentity()
                    HStack { Text("Commitment:").foregroundColor(.secondary); Text(bundle?.commitment ?? "—").font(.footnote).lineLimit(1).textSelection(.enabled) }
                    if let c = bundle?.commitment, let idx = group.indexOf(c) {
                        HStack { Text("Index:").foregroundColor(.secondary); Text("#\(idx)") }
                    } else {
                        Text("Not a member of this group yet").foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Root")
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { activeSheet = nil } } }
        }
    }

    private var AddMemberSheet: some View {
        NavigationView {
            Form {
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
            }
            .navigationTitle("Add User")
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { activeSheet = nil } } }
        }
    }

    private var RevokeMemberSheet: some View {
        NavigationView {
            Form {
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
            }
            .navigationTitle("Revoke User")
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { activeSheet = nil } } }
        }
    }

    private var InviteSheet: some View {
        NavigationView {
            Form {
                Section("Invite URL") {
                    let urlString = makeJoinURL()
                    if !urlString.isEmpty { Text(urlString).font(.footnote).textSelection(.enabled) }
                    HStack {
                        Button("Generate QR") { generateJoinQR() }.disabled(urlString.isEmpty)
                        Spacer()
                        Button("Copy URL") { UIPasteboard.general.string = urlString }.disabled(urlString.isEmpty)
                    }
                }
                if let img = joinQRImage {
                    Section {
                        Image(uiImage: img)
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                            .frame(height: 250)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("Invite")
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { activeSheet = nil } } }
        }
    }
}

#Preview {
    NavigationView { GroupManagementView() }
}

// MARK: - Tree UI Components

private struct NodeRow: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color(.systemBackground))
                        .overlay(Circle().stroke(Color.accentColor, lineWidth: 2))
                        .frame(width: 56, height: 56)
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.accentColor)
                }
                Text(title)
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct Connector: View {
    var body: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.3))
            .frame(width: 2, height: 24)
            .padding(.leading, 27)
    }
}


