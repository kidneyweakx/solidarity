
import BigInt
import Combine
import Foundation
import Web3
import Web3Auth
import SwiftUI

class Web3RPC : ObservableObject {
    var user: Web3AuthState
    private var web3: Web3
    public var address: EthereumAddress
    private var privateKey: EthereumPrivateKey
    private var latestBlock = 0
    private var chainID = 11155111
    private var RPC_URL = "https://1rpc.io/sepolia"
    
    @Published var balance: Double = 0
    @Published var signedMessageHashString:String = ""
    @Published var sentTransactionID:String = ""
    @Published var publicAddress: String = ""
    
    init?(user: Web3AuthState){
        self.user = user
        web3 = Web3(rpcURL: RPC_URL)
        guard let privKeyString = user.privKey,
              let privKeyData = Data(hexString: privKeyString) else {
            return nil
        }
        do {
            privateKey = try EthereumPrivateKey(privateKey: Array(privKeyData))
            address = privateKey.address
        } catch {
             return nil
        }
    }
    
    func getAccounts() {
        self.publicAddress = address.hex(eip55: true)
        print(address.hex(eip55: true))
    }
    

    func checkLatestBlockChanged() async -> Bool { true }

    func getBalance() {
        // TODO: Implement using Web3.swift callbacks once needed in UI
        // Keep existing balance; no-op for now to avoid build-time API drift
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.balance = self.balance
        }
    }

    
    func signMessage() {
        do {
            let messageData = "Hello World".data(using: .utf8)!
            let sig = try privateKey.sign(message: Array(messageData))
            let sigBytes: [UInt8] = sig.r + sig.s + [UInt8(sig.v)]
            let hex = bytesToHex(sigBytes)
            self.signedMessageHashString = hex
            print(hex)
        } catch {
            self.signedMessageHashString = "Something Went Wrong"
        }
    }
    
    func signMessage(message: String) throws -> String {
        do {
            let messageData = message.data(using: .utf8)!
            let sig = try privateKey.sign(message: Array(messageData))
            let sigBytes: [UInt8] = sig.r + sig.s + [UInt8(sig.v)]
            return bytesToHex(sigBytes)
        } catch {
            throw error
        }
    }
    
    func sendTransaction()  {
        // Not implemented in current flow; avoid compile errors with evolving API
        self.sentTransactionID = "Not implemented"
    }
    
    func transferAsset(sendTo: String, amount: Double, maxTip: Double, gasLimit: BigUInt = 21000) async throws -> String {
        // Not implemented; keep signature for compatibility
        throw SampleAppError.somethingWentWrong
    }

    private func bytesToHex(_ bytes: [UInt8]) -> String {
        bytes.map { String(format: "%02x", $0) }.joined()
    }
    
}

public enum SampleAppError:Error{
    
    case noInternetConnection
    case decodingError
    case somethingWentWrong
    case customErr(String)
}

extension Data {
    init?(hexString: String) {
        let len = hexString.count / 2
        var data = Data(capacity: len)
        var i = hexString.startIndex
        for _ in 0..<len {
            let j = hexString.index(i, offsetBy: 2)
            let bytes = hexString[i..<j]
            if var num = UInt8(bytes, radix: 16) {
                data.append(&num, count: 1)
            } else {
                return nil
            }
            i = j
        }
        self = data
    }
}