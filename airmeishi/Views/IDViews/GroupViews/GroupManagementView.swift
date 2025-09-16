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
        VStack(spacing: 0) {
            // Header Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Group Management")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Manage your groups and members")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .padding(.bottom, 24)
            
            // Main Actions Section
        ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Group Actions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Group Actions")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 0) {
                            ModernNodeRow(icon: "checkmark.seal", title: "View Root", subtitle: "Manage group root and identity") { activeSheet = .root }
                            Divider().padding(.leading, 60)
                            ModernNodeRow(icon: "person.badge.plus", title: "Add Member", subtitle: "Add new members to your group") { activeSheet = .add }
                            Divider().padding(.leading, 60)
                            ModernNodeRow(icon: "person.badge.minus", title: "Remove Member", subtitle: "Revoke member access") { activeSheet = .revoke }
                            Divider().padding(.leading, 60)
                            ModernNodeRow(icon: "qrcode", title: "Generate Invite", subtitle: "Create QR code or share link") { activeSheet = .invite }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                                .padding(.horizontal, 20)
                        )
                    }
                    
                    // Premium Features Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Premium Features")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 12) {
                            PremiumFeatureRow(
                                icon: "plus.circle.fill",
                                title: "Create Group with ENS",
                                subtitle: "Create groups with custom ENS domains",
                                price: "$5",
                                isEnabled: false
                            )
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarHidden(true)
        .safeAreaInset(edge: .top) {
            HStack {
                Button("Done") { dismiss() }
                    .font(.headline)
                    .foregroundColor(.accentColor)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(Color(.systemGroupedBackground))
        }
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
        guard group.selectedGroupId != nil else { return }
        isAddingMember = true
        group.addMember(commitment)
        isAddingMember = false
        newMemberCommitment = ""
    }

    // No randomEthAddress here; add member must reuse owner's address from creation

    // MARK: - Sheets

    private var RootSheet: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Group Root Management")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("View and manage your group's merkle root and identity")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    
                    // Group Selection
                if !group.allGroups.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Select Group")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 8) {
                        ForEach(group.allGroups) { g in
                                    Button(action: { group.selectGroup(g.id) }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                                Text(g.name)
                                                    .font(.headline)
                                                    .foregroundColor(.primary)
                                                Text(g.root ?? "No root available")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(1)
                                }
                                Spacer()
                                if group.selectedGroupId == g.id {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.accentColor)
                                                    .font(.title2)
                                            } else {
                                                Image(systemName: "circle")
                                                    .foregroundColor(.secondary)
                                                    .font(.title2)
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 16)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(group.selectedGroupId == g.id ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    // Merkle Root Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Merkle Root")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 16) {
                            // Root Display
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Current Root")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                Text(group.merkleRoot ?? "No root available")
                                    .font(.system(.body, design: .monospaced))
                                    .textSelection(.enabled)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(.systemGray6))
                                    )
                            }
                            .padding(.horizontal, 20)
                            
                            // Action Buttons
                            HStack(spacing: 12) {
                                Button(action: { group.recomputeRoot() }) {
                                    HStack {
                                        Image(systemName: "arrow.clockwise")
                                        Text("Recompute")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.accentColor)
                                    )
                                    .foregroundColor(.white)
                                }
                                
                                Button(action: { copyRoot() }) {
                                    HStack {
                                        Image(systemName: "doc.on.doc")
                                        Text("Copy")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.accentColor, lineWidth: 1)
                                    )
                                    .foregroundColor(.accentColor)
                                }
                                .disabled(group.merkleRoot == nil)
                            }
                            .padding(.horizontal, 20)
                            
                            // Sync Button
                    HStack {
                                if isFetchingRoot { 
                                    ProgressView()
                                        .controlSize(.small)
                                }
                                Button(action: { group.syncRootFromNetwork { _ in } }) {
                    HStack {
                                        Image(systemName: "icloud.and.arrow.down")
                                        Text("Sync from Network")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color(.systemGray3), lineWidth: 1)
                                    )
                                    .foregroundColor(.primary)
                                }
                                .disabled(isFetchingRoot)
                            }
                            .padding(.horizontal, 20)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                                .padding(.horizontal, 20)
                        )
                    }
                    
                    // ENS Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ENS Integration")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("ENS Name")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                    HStack {
                        TextField("mygroup.eth", text: $ensName)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color(.systemGray6))
                                        )
                                    
                                    Button(action: { resolveENS() }) {
                                        if isResolvingENS {
                                            ProgressView()
                                                .controlSize(.small)
                                        } else {
                                            Text("Resolve")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                        }
                                    }
                            .disabled(ensName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isResolvingENS)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.accentColor)
                                    )
                                    .foregroundColor(.white)
                                }
                            }
                            .padding(.horizontal, 20)
                            
                    if let addr = ensResolvedAddress, !addr.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Resolved Address")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                    
                                    Text(addr)
                                        .font(.system(.body, design: .monospaced))
                                        .textSelection(.enabled)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color(.systemGray6))
                                        )
                                }
                                .padding(.horizontal, 20)
                            }
                            
                            HStack {
                                if isFetchingRoot { 
                                    ProgressView()
                                        .controlSize(.small)
                                }
                                Button(action: { fetchRootViaENS() }) {
                    HStack {
                                        Image(systemName: "arrow.down.circle")
                                        Text("Fetch Root via ENS")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color(.systemGray3), lineWidth: 1)
                                    )
                                    .foregroundColor(.primary)
                                }
                            .disabled(ensName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isFetchingRoot)
                            }
                            .padding(.horizontal, 20)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                                .padding(.horizontal, 20)
                        )
                    }
                    
                    // Identity Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Identity")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 16) {
                            let bundle = SemaphoreIdentityManager.shared.getIdentity()
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Commitment")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                Text(bundle?.commitment ?? "No identity available")
                                    .font(.system(.body, design: .monospaced))
                                    .textSelection(.enabled)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(.systemGray6))
                                    )
                            }
                            .padding(.horizontal, 20)
                            
                    if let c = bundle?.commitment, let idx = group.indexOf(c) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Group Index")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                    
                                    Text("#\(idx)")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.accentColor)
                                }
                                .padding(.horizontal, 20)
                    } else {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundColor(.orange)
                                    Text("Not a member of this group yet")
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                                .padding(.horizontal, 20)
                        )
                    }
                    
                    Spacer(minLength: 40)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Root Management")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { 
                ToolbarItem(placement: .navigationBarTrailing) { 
                    Button("Done") { activeSheet = nil } 
                } 
            }
        }
    }

    private var AddMemberSheet: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Add Group Member")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Add new members to your group using various methods")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    
                    // Manual Entry Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Manual Entry")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Member Commitment")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                TextField("Enter member commitment", text: $newMemberCommitment)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(.systemGray6))
                                    )
                            }
                            .padding(.horizontal, 20)
                            
                            Button(action: { addMemberAction() }) {
                                HStack {
                                    if isAddingMember {
                                        ProgressView()
                                            .controlSize(.small)
                                            .foregroundColor(.white)
                                    } else {
                                        Image(systemName: "person.badge.plus")
                                    }
                                    Text(isAddingMember ? "Adding..." : "Add to Group")
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.accentColor)
                                )
                                .foregroundColor(.white)
                            }
                            .disabled(isAddingMember || newMemberCommitment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .padding(.horizontal, 20)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                                .padding(.horizontal, 20)
                        )
                    }
                    
                    // Nearby Discovery Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Nearby Discovery")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 16) {
                            // Scan Toggle
                    HStack {
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(proximity.isBrowsing ? Color.accentColor.opacity(0.1) : Color(.systemGray5))
                                            .frame(width: 40, height: 40)
                                        Image(systemName: proximity.isBrowsing ? "dot.radiowaves.right" : "dot.radiowaves.left.and.right")
                                            .foregroundColor(proximity.isBrowsing ? .accentColor : .secondary)
                                            .font(.system(size: 18, weight: .medium))
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(proximity.isBrowsing ? "Scanning Nearby" : "Scan for Nearby Devices")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                        Text(proximity.isBrowsing ? "Looking for nearby devices" : "Tap to start scanning")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                        Spacer()
                                
                                Button(action: {
                            if proximity.isBrowsing {
                                proximity.stopBrowsing()
                            } else {
                                proximity.startBrowsing()
                            }
                                }) {
                                    Text(proximity.isBrowsing ? "Stop" : "Start")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(proximity.isBrowsing ? Color.red : Color.accentColor)
                                        )
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            // Nearby Peers
                            if group.allGroups.isEmpty {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundColor(.orange)
                                    Text("Create a group first to invite members")
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 20)
                    } else if let gid = group.selectedGroupId, let g = group.allGroups.first(where: { $0.id == gid }) {
                                VStack(alignment: .leading, spacing: 12) {
                        HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Group: \(g.name)")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                            Text("\(proximity.nearbyPeers.count) nearby peers")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                            Spacer()
                        }
                                    .padding(.horizontal, 20)
                                    
                        if proximity.nearbyPeers.isEmpty {
                                        VStack(spacing: 8) {
                                            Image(systemName: "wifi.slash")
                                                .font(.largeTitle)
                                                .foregroundColor(.secondary)
                                            Text("No nearby peers found")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                            Text("Make sure other devices have the app open and are in Matching mode")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .multilineTextAlignment(.center)
                                        }
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 20)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color(.systemGray6))
                                                .padding(.horizontal, 20)
                                        )
                        } else {
                                        VStack(spacing: 8) {
                            ForEach(proximity.nearbyPeers) { peer in
                                HStack {
                                                    ZStack {
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .fill(Color.accentColor.opacity(0.1))
                                                            .frame(width: 36, height: 36)
                                                        Image(systemName: "person.circle")
                                                            .foregroundColor(.accentColor)
                                                            .font(.system(size: 18))
                                                    }
                                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                                        Text(peer.cardName ?? peer.name)
                                                            .font(.subheadline)
                                                            .fontWeight(.medium)
                                                        if let title = peer.cardTitle {
                                                            Text(title)
                                                                .font(.caption)
                                                                .foregroundColor(.secondary)
                                                        }
                                                    }
                                                    
                                    Spacer()
                                                    
                                                    Button(action: {
                                        let inviter = (try? CardManager.shared.getAllCards().get().first?.name) ?? CardManager.shared.businessCards.first?.name ?? UIDevice.current.name
                                        proximity.invitePeerToGroup(peer, group: g, inviterName: inviter)
                                                    }) {
                                        Image(systemName: "paperplane.fill")
                                                            .font(.system(size: 16, weight: .medium))
                                                            .foregroundColor(.white)
                                                            .padding(8)
                                                            .background(
                                                                Circle()
                                                                    .fill(Color.accentColor)
                                                            )
                                                    }
                                                }
                                                .padding(.horizontal, 20)
                                                .padding(.vertical, 12)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .fill(Color(.systemGray6))
                                                        .padding(.horizontal, 20)
                                                )
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                                .padding(.horizontal, 20)
                        )
                    }
                    
                    Spacer(minLength: 40)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Add Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { 
                ToolbarItem(placement: .navigationBarTrailing) { 
                    Button("Done") { activeSheet = nil } 
                } 
            }
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
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Remove Group Member")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Revoke access for group members")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    
                    // Members Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Group Members")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                            Text("\(group.members.count)")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.accentColor)
                        }
                        .padding(.horizontal, 20)
                        
                    if group.members.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "person.3")
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary)
                                Text("No members yet")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                Text("Add members to your group first")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 40)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                                    .padding(.horizontal, 20)
                            )
                    } else {
                            VStack(spacing: 8) {
                                ForEach(group.members, id: \.self) { member in
                            HStack {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.red.opacity(0.1))
                                                .frame(width: 36, height: 36)
                                            Image(systemName: "person.circle")
                                                .foregroundColor(.red)
                                                .font(.system(size: 18))
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Member")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                            Text(member)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                        }
                                        
                                Spacer()
                                        
                                        Button(action: { group.removeMember(member) }) {
                                            Image(systemName: "trash")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.white)
                                                .padding(8)
                                                .background(
                                                    Circle()
                                                        .fill(Color.red)
                                                )
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(.systemGray6))
                                            .padding(.horizontal, 20)
                                    )
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                                    .padding(.horizontal, 20)
                            )
                        }
                    }
                    
                    Spacer(minLength: 40)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Remove Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { 
                ToolbarItem(placement: .navigationBarTrailing) { 
                    Button("Done") { activeSheet = nil } 
                } 
            }
        }
    }

    private var InviteSheet: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Generate Invite")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Create shareable links and QR codes for group invitations")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    
                    // Invite URL Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Invite URL")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 16) {
                    let urlString = makeJoinURL()
                            
                            if !urlString.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Generated URL")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                    
                                    Text(urlString)
                                        .font(.system(.body, design: .monospaced))
                                        .textSelection(.enabled)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color(.systemGray6))
                                        )
                                }
                                .padding(.horizontal, 20)
                            }
                            
                            HStack(spacing: 12) {
                                Button(action: { generateJoinQR() }) {
                                    HStack {
                                        Image(systemName: "qrcode")
                                        Text("Generate QR Code")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.accentColor)
                                    )
                                    .foregroundColor(.white)
                                }
                                .disabled(urlString.isEmpty)
                                
                                Button(action: { UIPasteboard.general.string = urlString }) {
                    HStack {
                                        Image(systemName: "doc.on.doc")
                                        Text("Copy URL")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.accentColor, lineWidth: 1)
                                    )
                                    .foregroundColor(.accentColor)
                                }
                                .disabled(urlString.isEmpty)
                            }
                            .padding(.horizontal, 20)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                                .padding(.horizontal, 20)
                        )
                    }
                    
                    // QR Code Section
                if let img = joinQRImage {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("QR Code")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 16) {
                                VStack(spacing: 12) {
                        Image(uiImage: img)
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                            .frame(height: 250)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.white)
                                        )
                                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                    
                                    Text("Scan this QR code to join the group")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 20)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                                    .padding(.horizontal, 20)
                            )
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("QR Code")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 16) {
                                VStack(spacing: 12) {
                                    Image(systemName: "qrcode")
                                        .font(.largeTitle)
                                        .foregroundColor(.secondary)
                                        .padding(.vertical, 40)
                                    
                                    Text("Generate QR code to display here")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 20)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                                    .padding(.horizontal, 20)
                            )
                        }
                    }
                    
                    Spacer(minLength: 40)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Generate Invite")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { 
                ToolbarItem(placement: .navigationBarTrailing) { 
                    Button("Done") { activeSheet = nil } 
                } 
            }
        }
    }
}

#Preview {
    NavigationView { GroupManagementView() }
}

// MARK: - Modern UI Components

private struct ModernNodeRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.accentColor.opacity(0.1))
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.accentColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct PremiumFeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let price: String
    let isEnabled: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isEnabled ? Color.accentColor.opacity(0.1) : Color(.systemGray5))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(isEnabled ? .accentColor : .secondary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(isEnabled ? .primary : .secondary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(price)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(isEnabled ? .accentColor : .secondary)
                Text("Premium")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .opacity(isEnabled ? 1.0 : 0.6)
    }
}


