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

    @Published private(set) var members: [String] = []   // identity commitments (public)
    @Published private(set) var merkleRoot: String?      // latest root

    private let storage = GroupStorage()

    // Ensure @Published updates happen on main thread
    private func onMain(_ block: @escaping () -> Void) {
        if Thread.isMainThread { block() } else { DispatchQueue.main.async(execute: block) }
    }

    // MARK: - Persistence

    func load() {
        let state = storage.load()
        members = state.members
        merkleRoot = state.root
    }

    func save() { storage.save(members: members, root: merkleRoot) }

    // MARK: - Membership

    func setMembers(_ commitments: [String]) {
        onMain { [weak self] in
            guard let self = self else { return }
            self.members = Array(Set(commitments))
            self.recomputeRoot()
        }
        DispatchQueue.global(qos: .utility).async { [weak self] in self?.save() }
    }

    func addMember(_ commitment: String) {
        onMain { [weak self] in
            guard let self = self else { return }
            guard !self.members.contains(commitment) else { return }
            self.members.append(commitment)
            self.recomputeRoot()
        }
        DispatchQueue.global(qos: .utility).async { [weak self] in self?.save() }
    }

    func removeMember(_ commitment: String) {
        onMain { [weak self] in
            guard let self = self else { return }
            self.members.removeAll { $0 == commitment }
            self.recomputeRoot()
        }
        DispatchQueue.global(qos: .utility).async { [weak self] in self?.save() }
    }

    func indexOf(_ commitment: String) -> Int? { members.firstIndex(of: commitment) }

    // MARK: - Root

    func recomputeRoot() {
        #if canImport(Semaphore)
        // Build a minimal group using our local identity only to avoid relying on Element initializers.
        // TODO: Convert stored commitment strings to proper elements once supported by the bindings.
        var newRoot: String? = nil
        if let bundle = SemaphoreIdentityManager.shared.getIdentity() {
            let identity = Identity(privateKey: bundle.privateKey)
            let group = Group(members: [identity.toElement()])
            if let rootData = group.root() {
                newRoot = rootData.map { String(format: "%02x", $0) }.joined()
            }
        }
        onMain { [weak self] in self?.merkleRoot = newRoot }
        #else
        // Fallback: simple hash of members for display only
        let newRoot = String(members.joined(separator: ":").hashValue)
        onMain { [weak self] in self?.merkleRoot = newRoot }
        #endif
    }

    /// Update the current Merkle root from an external source (API/chain)
    func updateRoot(_ newRoot: String?) {
        onMain { [weak self] in self?.merkleRoot = newRoot }
        DispatchQueue.global(qos: .utility).async { [weak self] in self?.save() }
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

    struct State: Codable { let members: [String]; let root: String? }

    func load() -> State {
        guard let data = try? Data(contentsOf: url) else { return State(members: [], root: nil) }
        return (try? JSONDecoder().decode(State.self, from: data)) ?? State(members: [], root: nil)
    }

    func save(members: [String], root: String?) {
        let state = State(members: members, root: root)
        if let data = try? JSONEncoder().encode(state) { try? data.write(to: url) }
    }
}


