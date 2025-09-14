//
//  SemaphoreGroupManager.swift
//  airmeishi
//
//  Manages local view of Semaphore group membership and Merkle root.
//  NOTE: Root syncing with chain/API is stubbed with TODOs.
//

import Foundation
import Combine

#if canImport(Semaphore)
import Semaphore
#endif

final class SemaphoreGroupManager: ObservableObject {
    static let shared = SemaphoreGroupManager()
    private init() { load() }

    // Public-facing: state of the currently selected group
    @Published private(set) var members: [String] = []
    @Published private(set) var merkleRoot: String?

    // Multi-group state
    @Published private(set) var allGroups: [ManagedGroup] = []
    @Published private(set) var selectedGroupId: UUID?

    private let storage = GroupStorage()

    // Ensure @Published updates happen on main thread
    private func onMain(_ block: @escaping () -> Void) {
        if Thread.isMainThread { block() } else { DispatchQueue.main.async(execute: block) }
    }

    // MARK: - Persistence

    func load() {
        let state = storage.load()
        self.allGroups = state.groups
        self.selectedGroupId = state.selectedGroupId ?? state.groups.first?.id
        applySelectedToPublished()
    }

    func save() { storage.save(groups: allGroups, selectedGroupId: selectedGroupId) }

    // MARK: - Membership

    func setMembers(_ commitments: [String]) {
        onMain { [weak self] in
            guard let self = self else { return }
            guard let gid = self.selectedGroupId, let idx = self.allGroups.firstIndex(where: { $0.id == gid }) else {
                self.members = Array(Set(commitments))
                self.recomputeRoot()
                return
            }
            self.allGroups[idx].members = Array(Set(commitments))
            self.updateRootForGroup(at: idx)
            self.applySelectedToPublished()
        }
        DispatchQueue.global(qos: .utility).async { [weak self] in self?.save() }
    }

    func addMember(_ commitment: String) {
        onMain { [weak self] in
            guard let self = self else { return }
            guard let gid = self.selectedGroupId, let idx = self.allGroups.firstIndex(where: { $0.id == gid }) else { return }
            guard !self.allGroups[idx].members.contains(commitment) else { return }
            self.allGroups[idx].members.append(commitment)
            self.updateRootForGroup(at: idx)
            self.applySelectedToPublished()
        }
        DispatchQueue.global(qos: .utility).async { [weak self] in self?.save() }
    }

    func removeMember(_ commitment: String) {
        onMain { [weak self] in
            guard let self = self else { return }
            guard let gid = self.selectedGroupId, let idx = self.allGroups.firstIndex(where: { $0.id == gid }) else { return }
            self.allGroups[idx].members.removeAll { $0 == commitment }
            self.updateRootForGroup(at: idx)
            self.applySelectedToPublished()
        }
        DispatchQueue.global(qos: .utility).async { [weak self] in self?.save() }
    }

    func indexOf(_ commitment: String) -> Int? { members.firstIndex(of: commitment) }

    // MARK: - Root

    func recomputeRoot() {
        #if canImport(Semaphore)
        guard let gid = selectedGroupId, let idx = allGroups.firstIndex(where: { $0.id == gid }) else {
            onMain { [weak self] in self?.merkleRoot = nil }
            return
        }
        var newRoot: String? = nil
        if let bundle = SemaphoreIdentityManager.shared.getIdentity() {
            let identity = Identity(privateKey: bundle.privateKey)
            let group = Group(members: [identity.toElement()])
            if let rootData = group.root() {
                newRoot = rootData.map { String(format: "%02x", $0) }.joined()
            }
        }
        onMain { [weak self] in
            guard let self = self else { return }
            self.allGroups[idx].root = newRoot
            self.merkleRoot = newRoot
        }
        #else
        guard let gid = selectedGroupId, let idx = allGroups.firstIndex(where: { $0.id == gid }) else { return }
        let newRoot = String(allGroups[idx].members.joined(separator: ":").hashValue)
        onMain { [weak self] in
            self?.allGroups[idx].root = newRoot
            self?.merkleRoot = newRoot
        }
        #endif
    }

    /// Update the current Merkle root from an external source (API/chain)
    func updateRoot(_ newRoot: String?) {
        onMain { [weak self] in
            guard let self = self else { return }
            if let gid = self.selectedGroupId, let idx = self.allGroups.firstIndex(where: { $0.id == gid }) {
                self.allGroups[idx].root = newRoot
            }
            self.merkleRoot = newRoot
        }
        DispatchQueue.global(qos: .utility).async { [weak self] in self?.save() }
    }

    // MARK: - Multi-group management

    struct ManagedGroup: Codable, Identifiable, Equatable {
        let id: UUID
        var name: String
        var createdAt: Date
        var members: [String]
        var root: String?
    }

    @discardableResult
    func createGroup(name: String, initialMembers: [String] = []) -> ManagedGroup {
        let g = ManagedGroup(id: UUID(), name: name, createdAt: Date(), members: Array(Set(initialMembers)), root: nil)
        onMain { [weak self] in
            guard let self = self else { return }
            self.allGroups.append(g)
            self.selectedGroupId = g.id
            self.applySelectedToPublished()
        }
        DispatchQueue.global(qos: .utility).async { [weak self] in self?.save() }
        recomputeRoot()
        // Auto-create a simple card with the group name for now
        let cardName = name
        let card = BusinessCard(name: cardName)
        _ = CardManager.shared.createCard(card)
        return g
    }

    func selectGroup(_ id: UUID) {
        onMain { [weak self] in
            self?.selectedGroupId = id
            self?.applySelectedToPublished()
        }
    }

    private func updateRootForGroup(at index: Int) {
        #if canImport(Semaphore)
        var newRoot: String? = nil
        if let bundle = SemaphoreIdentityManager.shared.getIdentity() {
            let identity = Identity(privateKey: bundle.privateKey)
            let group = Group(members: [identity.toElement()])
            if let rootData = group.root() { newRoot = rootData.map { String(format: "%02x", $0) }.joined() }
        }
        self.allGroups[index].root = newRoot
        #else
        self.allGroups[index].root = String(self.allGroups[index].members.joined(separator: ":").hashValue)
        #endif
    }

    private func applySelectedToPublished() {
        if let gid = selectedGroupId, let g = allGroups.first(where: { $0.id == gid }) {
            self.members = g.members
            self.merkleRoot = g.root
        } else {
            self.members = []
            self.merkleRoot = nil
        }
    }

    // MARK: - Sync (Placeholders)

    /// TODO: Fetch latest group root from chain/API and update local state.
    func syncRootFromNetwork(completion: @escaping (Bool) -> Void) {
        // TODO: Replace with real on-chain or API fetch
        // For now, this is a stub. Expected behavior:
        // - fetch latest members or root from API or chain
        // - update `members` and `merkleRoot`
        // - call completion(true) on success
        completion(false)
    }

    /// TODO: Push local membership updates to chain/API.
    func pushUpdatesToNetwork(completion: @escaping (Bool) -> Void) {
        // TODO: Replace with real on-chain or API push
        // For now, this is a stub. Expected behavior:
        // - send membership diffs or full snapshot to API or chain
        // - receive confirmation and updated root
        // - update `merkleRoot` if necessary
        completion(false)
    }
}

// MARK: - Local storage

private final class GroupStorage {
    private let url: URL

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = dir.appendingPathComponent("airmeishi", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        url = appDir.appendingPathComponent("semaphore_group.json")
    }

    struct StoredGroup: Codable { let id: UUID; var name: String; var createdAt: Date; var members: [String]; var root: String? }
    struct State: Codable { let groups: [SemaphoreGroupManager.ManagedGroup]; let selectedGroupId: UUID? }

    func load() -> State {
        // Try new format
        if let data = try? Data(contentsOf: url), let decoded = try? JSONDecoder().decode(State.self, from: data) {
            return decoded
        }
        // Migrate from old single-group format if present
        struct LegacyState: Codable { let members: [String]; let root: String? }
        if let data = try? Data(contentsOf: url), let legacy = try? JSONDecoder().decode(LegacyState.self, from: data) {
            let g = SemaphoreGroupManager.ManagedGroup(id: UUID(), name: "Default", createdAt: Date(), members: legacy.members, root: legacy.root)
            return State(groups: [g], selectedGroupId: g.id)
        }
        return State(groups: [], selectedGroupId: nil)
    }

    func save(groups: [SemaphoreGroupManager.ManagedGroup], selectedGroupId: UUID?) {
        let state = State(groups: groups, selectedGroupId: selectedGroupId)
        if let data = try? JSONEncoder().encode(state) { try? data.write(to: url) }
    }
}


