//
//  ReownWalletManager.swift
//  airmeishi
//
//  Lightweight placeholder for wallet connection and signing.
//  Integrate Reown (WalletConnect) later; API is designed to be swappable.
//

import Foundation
import Combine

final class ReownWalletManager: ObservableObject {
    static let shared = ReownWalletManager()
    
    @Published private(set) var isConnected: Bool = false
    @Published private(set) var accountAddress: String? = nil
    @Published private(set) var displayName: String? = nil
    
    private init() {}
    
    /// Simulate wallet connection. Replace with Reown pairing flow.
    func connect() {
        guard !isConnected else { return }
        // Derive a pseudo address from app signing public key so we have a stable identifier
        let km = KeyManager.shared
        let result = km.getSigningKeyPair()
        if case .success(let pair) = result {
            let pubHex = pair.publicKey.rawRepresentation.map { String(format: "%02x", $0) }.joined()
            // Take last 40 chars as a pseudo 20-byte address
            let tail = String(pubHex.suffix(40))
            accountAddress = "0x" + tail
            displayName = "Wallet"
            isConnected = true
        }
    }
    
    func disconnect() {
        isConnected = false
        accountAddress = nil
        displayName = nil
    }
    
    /// Sign an arbitrary UTF-8 message; returns hex-encoded signature.
    func signMessage(_ message: String) -> String? {
        let km = KeyManager.shared
        let result = km.getSigningKeyPair()
        switch result {
        case .success(let pair):
            let data = Data(message.utf8)
            do {
                let sig = try pair.privateKey.signature(for: data)
                return sig.rawRepresentation.map { String(format: "%02x", $0) }.joined()
            } catch {
                return nil
            }
        case .failure:
            return nil
        }
    }
}


