import Foundation
import Combine
import CryptoKit
import UIKit

#if canImport(CoinbaseWalletSDK)
import CoinbaseWalletSDK
#endif

final class CoinbaseWalletService: ObservableObject {
    static let shared = CoinbaseWalletService()
    private init() {}

    // Sepolia configuration
    // chainId per Coinbase Wallet Mobile SDK API is an integer as string
    private let sepoliaChainId: String = "11155111"

    @Published private(set) var isConnected: Bool = false
    @Published private(set) var isRequestInFlight: Bool = false
    @Published private(set) var selectedAddress: String? = nil
    @Published private(set) var lastErrorMessage: String? = nil
    @Published private(set) var lastTransactionHash: String? = nil

    // MARK: - Handshake / Connect
    func connectAndRequestAccounts() {
        #if canImport(CoinbaseWalletSDK)
        guard !isRequestInFlight else { 
            print("🔗 [Wallet] Request already in flight, skipping")
            return 
        }
        print("🔗 [Wallet] Setting isRequestInFlight = true")
        isRequestInFlight = true

        print("🔗 [Wallet] Creating eth_requestAccounts action")
        let requestAccounts = Action(jsonRpc: .eth_requestAccounts)
        print("🔗 [Wallet] Action created: \(requestAccounts)")
        
        print("🔗 [Wallet] Calling initiateHandshake...")
        
        // Add timeout detection
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            guard let self = self else { return }
            if self.isRequestInFlight {
                print("🔗 [Wallet] Handshake timeout - no response after 10 seconds")
                self.isRequestInFlight = false
                self.lastErrorMessage = "Connection timeout - please try again"
            }
        }
        
        CoinbaseWalletSDK.shared.initiateHandshake(
            initialActions: [requestAccounts]
        ) { [weak self] result, account in
            print("🔗 [Wallet] Handshake callback received")
            print("🔗 [Wallet] Result: \(result)")
            print("🔗 [Wallet] Account: \(account?.address ?? "nil")")
            
            guard let self = self else { 
                print("🔗 [Wallet] Self is nil in callback")
                return 
            }
            
            DispatchQueue.main.async {
                print("🔗 [Wallet] Setting isRequestInFlight = false")
                self.isRequestInFlight = false
            }
            
            if let address = account?.address {
                print("🔗 [Wallet] Success! Address: \(address)")
                DispatchQueue.main.async {
                    self.selectedAddress = address
                    self.isConnected = true
                    self.lastErrorMessage = nil
                    print("🔗 [Wallet] Updated UI state - connected: \(self.isConnected), address: \(self.selectedAddress ?? "nil")")
                }
            } else if case .failure(let error) = result {
                print("🔗 [Wallet] Error: \(error.localizedDescription)")
                DispatchQueue.main.async { 
                    self.lastErrorMessage = error.localizedDescription
                    print("🔗 [Wallet] Set error message: \(self.lastErrorMessage ?? "nil")")
                }
            } else {
                print("🔗 [Wallet] No address and no error - unexpected state")
            }
        }
        print("🔗 [Wallet] initiateHandshake call completed")
        #else
        print("🔗 [Wallet] CoinbaseWalletSDK not available")
        self.lastErrorMessage = "CoinbaseWalletSDK not linked. Add via SPM."
        #endif
    }

    // MARK: - Requests
    func requestAccounts() {
        #if canImport(CoinbaseWalletSDK)
        guard !isRequestInFlight else { return }
        isRequestInFlight = true
        let requestAccounts = Action(jsonRpc: .eth_requestAccounts)
        CoinbaseWalletSDK.shared.makeRequest(Request(actions: [requestAccounts])) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async { self.isRequestInFlight = false }
            if case .failure(let error) = result {
                DispatchQueue.main.async { self.lastErrorMessage = error.localizedDescription }
            } else {
                DispatchQueue.main.async { self.isConnected = true }
            }
        }
        #else
        self.lastErrorMessage = "CoinbaseWalletSDK not linked. Add via SPM."
        #endif
    }

    func switchToSepoliaIfNeeded() {
        #if canImport(CoinbaseWalletSDK)
        let switchChain = Action(jsonRpc: .wallet_switchEthereumChain(chainId: sepoliaChainId))
        CoinbaseWalletSDK.shared.makeRequest(Request(actions: [switchChain])) { _ in }
        #endif
    }

    func addSepoliaChainIfNeeded(rpcURLs: [String] = ["https://1rpc.io/sepolia"]) {
        #if canImport(CoinbaseWalletSDK)
        let addChain = Action(jsonRpc: .wallet_addEthereumChain(
            chainId: sepoliaChainId,
            blockExplorerUrls: ["https://sepolia.etherscan.io"],
            chainName: "Sepolia",
            iconUrls: [],
            nativeCurrency: AddChainNativeCurrency(name: "Sepolia ETH", symbol: "ETH", decimals: 18),
            rpcUrls: rpcURLs
        ))
        CoinbaseWalletSDK.shared.makeRequest(Request(actions: [addChain])) { _ in }
        #endif
    }

    // Build and send ENS setText transaction to a known resolver address
    func sendENSSetText(domain: String, key: String, value: String, resolverAddress: String) {
        #if canImport(CoinbaseWalletSDK)
        guard let fromAddress = selectedAddress else {
            self.lastErrorMessage = "No account selected. Connect wallet first."
            return
        }

        guard let calldataHex = ENSCalldataEncoder.encodeSetText(domain: domain, key: key, value: value) else {
            self.lastErrorMessage = "Failed to encode ENS calldata"
            return
        }

        // Commented out per request: skip sending transaction for now
        // let sendTransaction =
        //       Action(jsonRpc: .eth_sendTransaction(
        //              fromAddress: fromAddress,
        //              toAddress: resolverAddress,
        //              weiValue: "0",
        //              data: "0x" + calldataHex,
        //              nonce: nil,
        //              gasPriceInWei: nil,
        //              maxFeePerGas: nil,
        //              maxPriorityFeePerGas: nil,
        //              gasLimit: nil,
        //              chainId: sepoliaChainId))

        // isRequestInFlight = true
        // CoinbaseWalletSDK.shared.makeRequest(Request(actions: [sendTransaction])) { [weak self] result in
        //     guard let self = self else { return }
        //     DispatchQueue.main.async { self.isRequestInFlight = false }
        //     if case .failure(let error) = result {
        //         DispatchQueue.main.async { self.lastErrorMessage = error.localizedDescription }
        //     } else {
        //         DispatchQueue.main.async { self.lastErrorMessage = nil }
        //     }
        // }
        #else
        self.lastErrorMessage = "CoinbaseWalletSDK not linked. Add via SPM."
        #endif
    }

    // MARK: - URL Handling
    @discardableResult
    func handleOpenURL(_ url: URL) -> Bool {
        #if canImport(CoinbaseWalletSDK)
        return (try? CoinbaseWalletSDK.shared.handleResponse(url)) == true
        #else
        return false
        #endif
    }

    // MARK: - Generic request helpers
    #if canImport(CoinbaseWalletSDK)
    typealias SDKResponse = BaseMessage<[Result<JSONString, ActionError>]>

    func make(actions: [Action], completion: @escaping (Result<SDKResponse, Error>) -> Void) {
        CoinbaseWalletSDK.shared.makeRequest(Request(actions: actions)) { result in
            completion(result)
        }
    }

    func signTypedDataV3(typedData: [String: Any], completion: @escaping (Result<SDKResponse, Error>) -> Void) {
        guard let address = selectedAddress, !address.isEmpty else {
            completion(.failure(NSError(domain: "CBW", code: -1, userInfo: [NSLocalizedDescriptionKey: "No connected address"])))
            return
        }
        guard let json = JSONString(encode: typedData) else {
            completion(.failure(NSError(domain: "CBW", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid typed data JSON"])))
            return
        }
        let action = Action(jsonRpc: .eth_signTypedData_v3(address: address, typedDataJson: json))
        make(actions: [action], completion: completion)
    }
    #endif

    // MARK: - Helpers (none)
}

// MARK: - ENS calldata encoder
enum ENSCalldataEncoder {
    // function selector for setText(bytes32,string,string)
    private static let selectorHex = "59d1d43c" // keccak256("setText(bytes32,string,string)")[0..4]

    static func encodeSetText(domain: String, key: String, value: String) -> String? {
        guard let node = namehashHex(domain) else { return nil }
        let encoded = selectorHex + abiEncodeBytes32(node) + abiEncodeTwoStrings(key, value)
        return encoded
    }

    // Namehash per EIP-137
    private static func namehashHex(_ domain: String) -> String? {
        let labels = domain.split(separator: ".").map(String.init)
        var node = Data(repeating: 0, count: 32)
        for label in labels.reversed() {
            guard let labelHash = keccak256(data: Data(label.utf8)) else { return nil }
            var combined = Data()
            combined.append(node)
            combined.append(labelHash)
            guard let hashed = keccak256(data: combined) else { return nil }
            node = hashed
        }
        return node.map { String(format: "%02x", $0) }.joined()
    }

    private static func keccak256(data: Data) -> Data? {
        // CryptoKit doesn't provide keccak; if an external keccak is missing, return nil
        // In production, link a keccak implementation. Here we fail gracefully.
        return nil
    }

    // ABI encoding helpers
    private static func abiEncodeBytes32(_ hex: String) -> String {
        let without0x = hex.hasPrefix("0x") ? String(hex.dropFirst(2)) : hex
        let padded = without0x.leftPadded(to: 64, with: "0")
        return padded
    }

    private static func abiEncodeTwoStrings(_ a: String, _ b: String) -> String {
        // Minimal ABI encoder for two dynamic strings
        // layout: head(3*32) | tail(strA) | tail(strB)
        _ = 3 * 32
        let aBytes = Array(a.utf8)
        let bBytes = Array(b.utf8)
        let aLen = aBytes.count
        _ = bBytes.count

        // Offsets are from start of dynamic section (after the head)
        let offsetA = 32 * 3
        let offsetB = offsetA + 32 + ((aLen + 31) / 32) * 32

        var head = ""
        head += String(format: "%064x", offsetA)
        head += String(format: "%064x", offsetB)

        // placeholder for future static field count if needed (none here), keep third word as 0
        head += String(repeating: "0", count: 64)

        func encodeDyn(_ bytes: [UInt8]) -> String {
            var out = String(format: "%064x", bytes.count)
            var dataHex = bytes.map { String(format: "%02x", $0) }.joined()
            let paddedLen = ((bytes.count + 31) / 32) * 32 * 2
            dataHex = dataHex.rightPadded(to: paddedLen, with: "0")
            out += dataHex
            return out
        }

        let tailA = encodeDyn(aBytes)
        let tailB = encodeDyn(bBytes)

        return head + tailA + tailB
    }
}

private extension String {
    func leftPadded(to length: Int, with pad: Character) -> String {
        if self.count >= length { return self }
        return String(repeating: String(pad), count: max(0, length - self.count)) + self
    }
    func rightPadded(to length: Int, with pad: Character) -> String {
        if self.count >= length { return self }
        return self + String(repeating: String(pad), count: max(0, length - self.count))
    }
}


