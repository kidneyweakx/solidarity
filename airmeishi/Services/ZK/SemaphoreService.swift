//
//  SemaphoreService.swift
//  airmeishi
//
//  NOTE: This file remains as design notes; functionality moved into
//  `SemaphoreIdentityManager` and `SemaphoreGroupManager` with canImport guards.
//
//  TODO:
//  - Add SwiftPM dependency for `SemaphoreSwift` when ready
//  - Map `SharingLevel` -> scope/message
//
//  Reference: https://github.com/zkmopro/SemaphoreSwift
//
/*
import Foundation
import Semaphore

/// Abstraction over Semaphore identity and proof generation for business cards
final class SemaphoreService {
    static let shared = SemaphoreService()

    private init() {}

    enum ServiceError: Error { case invalidState, failed(String) }

    /// Creates or loads a persistent identity from secret bytes
    func loadOrCreateIdentity(secret: Data) throws -> Identity {
        // TODO: Store secret safely in Keychain and derive Identity
        return Identity(privateKey: secret)
    }

    /// Builds a group from known identity commitments
    func buildGroup(members: [Identity]) -> Group {
        let elements = members.map { $0.toElement() }
        return Group(members: elements)
    }

    /// Generates a semaphore proof for a given scope (sharing level) and message
    func generateProof(identity: Identity, group: Group, message: String, scope: String, depth: Int = 16) throws -> String {
        return try generateSemaphoreProof(
            identity: identity,
            group: group,
            message: message,
            scope: scope,
            merkleTreeDepth: depth
        )
    }

    /// Verifies a semaphore proof JSON string
    func verifyProof(_ proof: String) throws -> Bool {
        return try verifySemaphoreProof(proof: proof)
    }
}
*/


