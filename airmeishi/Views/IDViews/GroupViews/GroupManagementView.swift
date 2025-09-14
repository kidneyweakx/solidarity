//
//  GroupManagementView.swift
//  airmeishi
//
//  Manage group membership: view root, add/remove members, join via code/url.
//

import SwiftUI
import UIKit
import MultipeerConnectivity

struct GroupManagementView: View {
    @StateObject private var group = SemaphoreGroupManager.shared
    @StateObject private var proximity = ProximityManager.shared
    @State private var newMemberCommitment: String = ""
    @State private var isAddingMember: Bool = false
    @State private var addMemberErrorMessage: String? = nil
    @State private var showAddMemberError: Bool = false
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
        .onReceive(NotificationCenter.default.publisher(for: .groupInviteReceived)) { _ in
            // A separate global UI can present ConnectGroupInvitePopupView when needed
        }
        .onReceive(NotificationCenter.default.publisher(for: .groupMembershipUpdated)) { _ in
            // Refresh published state to reflect latest membership/root
            group.load()
        }
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
        .alert("Add Member Failed", isPresented: $showAddMemberError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(addMemberErrorMessage ?? "Unknown error")
        }
    }

    // MARK: - Helpers

    private func resolveENS() {
        // Old ENS service removed; no-op in this build
        ensResolvedAddress = nil
    }

    private func fetchRootViaENS() {
        // Old API removed; rely on local root or other sync
        isFetchingRoot = false
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

    private func addMemberAction() {
        let commitment = newMemberCommitment.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !commitment.isEmpty else { return }
        guard let gid = group.selectedGroupId, let current = group.allGroups.first(where: { $0.id == gid }) else { return }
        isAddingMember = true
        // Use group owner's address created during group creation; fallback to empty string if unavailable
        let owner = current.ownerAddress ?? ""
        let payload = AddGroupMemberRequest(userId: commitment, ownerAddress: owner)
        Task {
            let service = GroupsService()
            let result = await service.addMember(groupName: current.name, payload: payload)
            switch result {
            case .success(let resp):
                // Update local state to mirror server
                group.setMembers(resp.members)
                group.updateRoot(resp.tree_root)
                DispatchQueue.main.async {
                    isAddingMember = false
                    newMemberCommitment = ""
                }
            case .failure:
                // Ignore API error: still add locally
                DispatchQueue.main.async {
                    group.addMember(commitment)
                    isAddingMember = false
                    newMemberCommitment = ""
                }
            }
        }
    }

    // No randomEthAddress here; add member must reuse owner's address from creation

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
                Section("Nearby Matching") {
                    HStack {
                        Label(proximity.isBrowsing ? "Scanning Nearby" : "Scan Nearby", systemImage: proximity.isBrowsing ? "dot.radiowaves.right" : "dot.radiowaves.left.and.right")
                        Spacer()
                        Button(proximity.isBrowsing ? "Stop" : "Start") {
                            if proximity.isBrowsing {
                                proximity.stopBrowsing()
                            } else {
                                proximity.startBrowsing()
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
                Section("Add Member") {
                    TextField("Commitment", text: $newMemberCommitment)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button(isAddingMember ? "Adding..." : "Add to Group") { addMemberAction() }
                        .disabled(isAddingMember || newMemberCommitment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                Section("Invite Nearby (AirDrop-like)") {
                    if group.allGroups.isEmpty {
                        Text("Create a group first").foregroundColor(.secondary)
                    } else if let gid = group.selectedGroupId, let g = group.allGroups.first(where: { $0.id == gid }) {
                        HStack {
                            Text(g.name)
                            Spacer()
                            Text("Peers: \(proximity.nearbyPeers.count)").foregroundColor(.secondary)
                        }
                        if proximity.nearbyPeers.isEmpty {
                            Text("No nearby peers. Open Matching to discover peers.").font(.caption).foregroundColor(.secondary)
                        } else {
                            ForEach(proximity.nearbyPeers) { peer in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(peer.cardName ?? peer.name).font(.subheadline)
                                        if let title = peer.cardTitle { Text(title).font(.caption2).foregroundColor(.secondary) }
                                    }
                                    Spacer()
                                    Button {
                                        let inviter = (try? CardManager.shared.getAllCards().get().first?.name) ?? CardManager.shared.businessCards.first?.name ?? UIDevice.current.name
                                        proximity.invitePeerToGroup(peer, group: g, inviterName: inviter)
                                    } label: {
                                        Image(systemName: "paperplane.fill")
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add User")
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { activeSheet = nil } } }
            .onAppear {
                if !proximity.isBrowsing { proximity.startBrowsing() }
            }
            .onDisappear {
                if proximity.isBrowsing { proximity.stopBrowsing() }
            }
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


