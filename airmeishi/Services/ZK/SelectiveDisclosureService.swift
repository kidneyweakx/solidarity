//
//  SelectiveDisclosureService.swift
//  airmeishi
//
//  NOTE: This file is entirely commented out. It sketches a service layer
//  for selective disclosure over business card fields (ZK-friendly design).
//  Do NOT compile yet. Keep as design notes with TODOs.
//
//  TODO:
//  - Decide on circuit and commitments per field
//  - Encode `BusinessCard` fields into commitments
//  - Provide `prove(fields:subset:, scope:)` and `verify(proof:)`
//  - Integrate with `SemaphoreService` when ready
//  - Add rate-limiting / nullifier strategy
//
/*
import Foundation

struct FieldCommitment: Codable, Hashable {
    let field: String
    let commitment: Data
}

/// Plans the interface for selective disclosure proofs
final class SelectiveDisclosureService {
    static let shared = SelectiveDisclosureService()
    private init() {}

    enum DisclosureError: Error { case notInitialized, failed(String) }

    /// Derive commitments for each field
    func deriveCommitments(from card: BusinessCard) throws -> [FieldCommitment] {
        // TODO: Hash/commit per-field value
        return []
    }

    /// Generate a proof that reveals only specific fields are authorized under `scope`
    func prove(allowedFields: [String], scope: String) throws -> Data {
        // TODO: Generate proof
        return Data()
    }

    /// Verify an incoming selective disclosure proof
    func verify(_ proof: Data) throws -> Bool {
        // TODO: Verify proof
        return false
    }
}
*/


