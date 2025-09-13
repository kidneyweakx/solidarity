//
//  SemaphoreGroupManager.swift
//  airmeishi
//
//  Manages local view of Semaphore group membership and Merkle root.
//  NOTE: Root syncing with chain/API is stubbed with TODOs.
//

import Foundation

#if canImport(Semaphore)
import Semaphore
#endif

final class SemaphoreGroupManager: ObservableObject {
    static let shared = SemaphoreGroupManager()
    private init() { load() }

    @Published private(set) var members: [String] = []   // identity commitments (public)
    @Published private(set) var merkleRoot: String?      // latest root

    private let storage = GroupStorage()

    // MARK: - Persistence

    func load() {
        let state = storage.load()
        members = state.members
        merkleRoot = state.root
    }

    func save() { storage.save(members: members, root: merkleRoot) }

    // MARK: - Membership

    func setMembers(_ commitments: [String]) {
        members = Array(Set(commitments))
        recomputeRoot()
        save()
    }

    func addMember(_ commitment: String) {
        guard !members.contains(commitment) else { return }
        members.append(commitment)
        recomputeRoot()
        save()
    }

    func removeMember(_ commitment: String) {
        members.removeAll { $0 == commitment }
        recomputeRoot()
        save()
    }

    func indexOf(_ commitment: String) -> Int? { members.firstIndex(of: commitment) }

    // MARK: - Root

    func recomputeRoot() {
        #if canImport(Semaphore)
        let elements = members.map { Element($0) }
        let group = Group(members: elements)
        merkleRoot = group.root()
        #else
        // Fallback: simple hash of members for display only
        merkleRoot = String(members.joined(separator: ":").hashValue)
        #endif
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


