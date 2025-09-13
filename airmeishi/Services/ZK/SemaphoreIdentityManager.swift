//
//  SemaphoreIdentityManager.swift
//  airmeishi
//
//  Manages Semaphore identity lifecycle, commitments, and proof helpers.
//  Uses Keychain to store the private identity secret locally.
//

import Foundation

#if canImport(Semaphore)
import Semaphore
#endif

/// Stores and manages Semaphore identity material. All identity secrets stay local.
final class SemaphoreIdentityManager: ObservableObject {
    static let shared = SemaphoreIdentityManager()

    private init() {}

    private let keychain = IdentityKeychain()

    struct IdentityBundle: Codable, Equatable {
        let privateKey: Data        // trapdoor + nullifier source (as used by SemaphoreSwift)
        let commitment: String      // public commitment hex/string
    }

    enum Error: Swift.Error { case notInitialized, storageFailed(String), unsupported }

    // MARK: - Identity

    /// Load existing identity or create a new one with random secret.
    func loadOrCreateIdentity() throws -> IdentityBundle {
        if let existing = try? keychain.loadIdentity() { return existing }

        let secret = randomSecret32()

        #if canImport(Semaphore)
        let identity = Identity(privateKey: secret)
        let commitment = identity.commitment()
        let bundle = IdentityBundle(privateKey: secret, commitment: commitment)
        try keychain.storeIdentity(bundle)
        return bundle
        #else
        let bundle = IdentityBundle(privateKey: secret, commitment: "")
        try keychain.storeIdentity(bundle)
        return bundle
        #endif
    }

    /// Returns current identity bundle if present.
    func getIdentity() -> IdentityBundle? { try? keychain.loadIdentity() }

    /// Replaces identity with provided secret bytes.
    func importIdentity(privateKey: Data) throws -> IdentityBundle {
        #if canImport(Semaphore)
        let identity = Identity(privateKey: privateKey)
        let commitment = identity.commitment()
        let bundle = IdentityBundle(privateKey: privateKey, commitment: commitment)
        try keychain.storeIdentity(bundle)
        return bundle
        #else
        let bundle = IdentityBundle(privateKey: privateKey, commitment: "")
        try keychain.storeIdentity(bundle)
        return bundle
        #endif
    }

    // MARK: - Proof helpers

    /// Generate a Semaphore proof JSON string for a message/scope within a group.
    /// Group members should be provided as commitments (hex/strings) including own commitment.
    func generateProof(groupCommitments: [String], message: String, scope: String, merkleDepth: Int = 16) throws -> String {
        #if canImport(Semaphore)
        guard let bundle = try? keychain.loadIdentity() else { throw Error.notInitialized }
        let identity = Identity(privateKey: bundle.privateKey)
        let elements = groupCommitments.map { Element($0) }
        let group = Group(members: elements)
        return try generateSemaphoreProof(
            identity: identity,
            group: group,
            message: message,
            scope: scope,
            merkleTreeDepth: merkleDepth
        )
        #else
        throw Error.unsupported
        #endif
    }

    /// Verify a Semaphore proof JSON string.
    func verifyProof(_ proof: String) throws -> Bool {
        #if canImport(Semaphore)
        return try verifySemaphoreProof(proof: proof)
        #else
        return false
        #endif
    }

    // MARK: - Utilities

    private func randomSecret32() -> Data {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes)
    }
}

// MARK: - Keychain storage for identity

private final class IdentityKeychain {
    private let tag = "com.kidneyweakx.airmeishi.semaphore.identity"

    func storeIdentity(_ bundle: SemaphoreIdentityManager.IdentityBundle) throws {
        let data = try JSONEncoder().encode(bundle)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tag,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw SemaphoreIdentityManager.Error.storageFailed("SecItemAdd: \(status)") }
    }

    func loadIdentity() throws -> SemaphoreIdentityManager.IdentityBundle? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tag,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = result as? Data else { throw SemaphoreIdentityManager.Error.storageFailed("SecItemCopyMatching: \(status)") }
        return try JSONDecoder().decode(SemaphoreIdentityManager.IdentityBundle.self, from: data)
    }
}


