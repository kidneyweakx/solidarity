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
    @State private var activeSheet: SheetType? = nil
    @State private var showDeleteConfirm: Bool = false
    @State private var isAnimating: Bool = false
    @Environment(\.dismiss) private var dismiss

    private enum SheetType: String, Identifiable {
        case root, add, revoke, ens
        var id: String { rawValue }
    }

    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.2),
                    Color(red: 0.2, green: 0.1, blue: 0.3),
                    Color(red: 0.1, green: 0.2, blue: 0.3)
                ],
                startPoint: isAnimating ? .topLeading : .bottomLeading,
                endPoint: isAnimating ? .bottomTrailing : .topTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 8).repeatForever(autoreverses: true), value: isAnimating)

            // Floating orbs for depth
            GeometryReader { geometry in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.blue.opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 200
                        )
                    )
                    .frame(width: 400, height: 400)
                    .offset(x: -100, y: isAnimating ? -50 : 50)
                    .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true), value: isAnimating)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.purple.opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 200
                        )
                    )
                    .frame(width: 300, height: 300)
                    .offset(x: geometry.size.width - 150, y: isAnimating ? geometry.size.height - 100 : geometry.size.height - 200)
                    .animation(.easeInOut(duration: 7).repeatForever(autoreverses: true), value: isAnimating)
            }

            VStack(spacing: 0) {
                // Enhanced Header Section with glassmorphism
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 16) {
                        // Icon with gradient
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue, Color.purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 60, height: 60)
                                .shadow(color: Color.blue.opacity(0.5), radius: 15, x: 0, y: 5)

                            Image(systemName: "person.3.sequence.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                        }
                        .scaleEffect(isAnimating ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Group Management")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white, Color.blue.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )

                            Text("Manage your groups and members")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }

                        Spacer()
                    }
                    .padding(24)
                }
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color.white.opacity(0.1))
                        .background(
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
                )
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 24)

                // Main Actions Section with enhanced cards
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Group Actions with glass card
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Group Actions")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)

                                Spacer()

                                Image(systemName: "sparkles")
                                    .foregroundColor(.yellow)
                                    .font(.title3)
                                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                                    .animation(.linear(duration: 10).repeatForever(autoreverses: false), value: isAnimating)
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 8)

                            VStack(spacing: 1) {
                                EnhancedNodeRow(icon: "checkmark.seal", title: "View Root", subtitle: "Manage group root and identity", gradientColors: [.blue, .cyan]) { activeSheet = .root }
                                EnhancedNodeRow(icon: "person.badge.plus", title: "Add Member", subtitle: "Add new members to your group", gradientColors: [.green, .mint]) { activeSheet = .add }
                                EnhancedNodeRow(icon: "person.badge.minus", title: "Remove Member", subtitle: "Revoke member access", gradientColors: [.orange, .yellow]) { activeSheet = .revoke }
                                EnhancedNodeRow(icon: "sparkles", title: "ENS Mode", subtitle: "Upgrade or bind to ENS", gradientColors: [.purple, .pink]) { activeSheet = .ens }
                                EnhancedDangerNodeRow(icon: "trash", title: "Delete Group", subtitle: "Remove group and its card") { showDeleteConfirm = true }
                            }
                        }
                        .padding(4)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.white.opacity(0.08))
                                .background(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                                .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
                        )
                        .padding(.horizontal, 20)

                        // Enhanced Premium Features
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Premium Features")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)

                                Spacer()

                                Image(systemName: "crown.fill")
                                    .foregroundColor(.yellow)
                                    .font(.title3)
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 8)

                            EnhancedPremiumFeatureRow(
                                icon: "plus.circle.fill",
                                title: "Create Group with ENS",
                                subtitle: "Create groups with custom ENS domains",
                                price: "$5",
                                isEnabled: false
                            )
                        }
                        .padding(4)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.yellow.opacity(0.15), Color.orange.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .background(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                                )
                                .shadow(color: Color.yellow.opacity(0.3), radius: 20, x: 0, y: 10)
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
            .safeAreaInset(edge: .top) {
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "xmark.circle.fill")
                            Text("Done")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.15))
                                .background(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            isAnimating = true
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
            case .ens:
                ENSSheet
            }
        }
        .alert("Add Member Failed", isPresented: $showAddMemberError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(addMemberErrorMessage ?? "Unknown error")
        }
        .alert("Delete Group?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                group.deleteSelectedGroup()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove the group and its associated card. This action cannot be undone.")
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

    // Invite URL and QR generation removed in favor of ENS Mode

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
                                            .fill(Color.Theme.primaryAction)
                                    )
                                    .foregroundColor(Color.Theme.buttonText)
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
                                            .fill(Color.Theme.primaryAction)
                                    )
                                    .foregroundColor(Color.Theme.buttonText)
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
                                            .foregroundColor(Color.Theme.buttonText)
                                    } else {
                                        Image(systemName: "person.badge.plus")
                                    }
                                    Text(isAddingMember ? "Adding..." : "Add to Group")
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.Theme.primaryAction)
                                )
                                .foregroundColor(Color.Theme.buttonText)
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
                                                .fill(proximity.isBrowsing ? Color.Theme.danger : Color.Theme.primaryAction)
                                        )
                                        .foregroundColor(Color.Theme.buttonText)
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
                                                            .foregroundColor(Color.Theme.buttonText)
                                                            .padding(8)
                                                            .background(
                                                                Circle()
                                                                    .fill(Color.Theme.primaryAction)
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
                                                .foregroundColor(Color.Theme.buttonText)
                                                .padding(8)
                                                .background(
                                                    Circle()
                                                        .fill(Color.Theme.danger)
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

    private var ENSSheet: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ENS Mode")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Upgrade or bind your group to ENS")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)

                    // Upgrade Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Upgrade")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 20)

                        VStack(spacing: 12) {
                            EnhancedPremiumFeatureRow(
                                icon: "sparkles",
                                title: "Upgrade to ENS Mode",
                                subtitle: "Advanced features backed by ENS",
                                price: "$5",
                                isEnabled: false
                            )
                        }
                        .padding(.horizontal, 20)
                    }

                    // Bind Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Bind to ENS")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 20)

                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("ENS Name")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)

                                TextField("mygroup.eth", text: $ensName)
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

                            Button(action: { /* TODO: bind to ENS when backend ready */ }) {
                                HStack {
                                    Image(systemName: "link")
                                    Text("Bind")
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.Theme.primaryAction)
                                )
                                .foregroundColor(Color.Theme.buttonText)
                            }
                            .disabled(ensName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .padding(.horizontal, 20)

                            Text("Binding requires network support and will be available soon.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 20)
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
            .navigationTitle("ENS Mode")
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

// MARK: - Enhanced UI Components

private struct EnhancedNodeRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let gradientColors: [Color]
    let action: () -> Void

    @State private var isPressed = false
    @State private var isHovered = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
            action()
        }) {
            HStack(alignment: .center, spacing: 16) {
                // Enhanced icon with gradient background
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: gradientColors.map { $0.opacity(0.3) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    LinearGradient(
                                        colors: gradientColors.map { $0.opacity(0.5) },
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .shadow(color: gradientColors.first?.opacity(0.3) ?? Color.clear, radius: 10, x: 0, y: 5)

                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .scaleEffect(isPressed ? 0.95 : (isHovered ? 1.05 : 1.0))
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .opacity(isHovered ? 1.0 : 0.6)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(isHovered ? 0.12 : 0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

private struct EnhancedPremiumFeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let price: String
    let isEnabled: Bool

    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Premium icon with crown effect
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [Color.yellow.opacity(0.4), Color.orange.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.yellow.opacity(0.6), Color.orange.opacity(0.4)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: Color.yellow.opacity(0.4), radius: 15, x: 0, y: 5)

                Image(systemName: icon)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.yellow, Color.orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Shimmer effect for premium
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.clear, Color.white.opacity(0.3), Color.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 80)
                    .offset(x: shimmerOffset)
                    .mask(RoundedRectangle(cornerRadius: 18))
            }
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    shimmerOffset = 200
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Image(systemName: "crown.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                }

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(price)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.yellow, Color.orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Premium")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.yellow.opacity(0.2))
                    )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.15), Color.white.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1.5)
                )
                .shadow(color: Color.yellow.opacity(0.2), radius: 15, x: 0, y: 8)
        )
        .padding(.horizontal, 12)
        .opacity(isEnabled ? 1.0 : 0.6)
    }
}

private struct EnhancedDangerNodeRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    @State private var isPressed = false
    @State private var isHovered = false
    @State private var warningPulse = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
            action()
        }) {
            HStack(alignment: .center, spacing: 16) {
                // Danger icon with warning animation
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Color.red.opacity(0.3), Color.pink.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.red.opacity(warningPulse ? 0.6 : 0.3), lineWidth: 2)
                                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: warningPulse)
                        )
                        .shadow(color: Color.red.opacity(0.3), radius: 10, x: 0, y: 5)

                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.red)
                }
                .scaleEffect(isPressed ? 0.95 : (isHovered ? 1.05 : 1.0))
                .onAppear {
                    warningPulse = true
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)

                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.red)
                    .opacity(isHovered ? 1.0 : 0.6)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.red.opacity(isHovered ? 0.12 : 0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.red.opacity(0.2), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}


