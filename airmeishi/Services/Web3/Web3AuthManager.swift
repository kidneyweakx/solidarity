import Foundation
import Combine
import UIKit
import Web3

#if canImport(Web3Auth)
import Web3Auth
#endif

final class Web3AuthManager: ObservableObject {
	static let shared = Web3AuthManager()
	
	@Published private(set) var isLoggedIn: Bool = false
	@Published private(set) var address: String? = nil
	@Published private(set) var displayName: String? = nil
	@Published private(set) var user: Web3AuthState? = nil
	@Published private(set) var lastError: CardError?
	@Published private(set) var isLoading: Bool = false
	
	private var web3Auth: Web3Auth?
	private let clientId = "BIrqtSxWou0y6Unpm_cFXcCSgqLXUldpnioD685xpd1ABC7cTDmOb6f_qA3MoM1naMeA-IWptPJ0wcNmgWzkCug"
	
	private init() {
		Task {
			await setup()
		}
	}
	
	// MARK: - Setup
	
	private func setup() async {
		#if canImport(Web3Auth)
		guard web3Auth == nil else { return }
		
		await MainActor.run {
			isLoading = true
		}
		
		do {
			web3Auth = try await Web3Auth(W3AInitParams(
				clientId: clientId,
				network: .sapphire_mainnet,
				redirectUrl: "airmeishi://auth"
			))
			
			await MainActor.run {
				if let state = web3Auth?.state {
					user = state
					isLoggedIn = true
					updateUserInfo()
				}
				isLoading = false
			}
		} catch {
			await MainActor.run {
				lastError = .networkError("Web3Auth setup failed: \(error.localizedDescription)")
				isLoading = false
			}
		}
		#else
		lastError = .networkError("Web3Auth SDK not linked. Add via SPM and import in this target.")
		#endif
	}
	
	// MARK: - Public API
	
	func login() {
		#if canImport(Web3Auth)
		guard let web3Auth = web3Auth else {
			lastError = .networkError("Web3Auth not initialized")
			return
		}
		
		Task {
			await MainActor.run {
				isLoading = true
			}
			
			do {
				let result = try await web3Auth.login(
					W3ALoginParams(loginProvider: .GOOGLE)
				)
				
				await MainActor.run {
					user = result
					isLoggedIn = true
					updateUserInfo()
					isLoading = false
				}
			} catch {
				await MainActor.run {
					lastError = .networkError("Login failed: \(error.localizedDescription)")
					isLoading = false
				}
			}
		}
		#else
		lastError = .networkError("Web3Auth SDK not linked. Add via SPM and import in this target.")
		#endif
	}
	
	func loginWithEmail(_ email: String) {
		#if canImport(Web3Auth)
		guard let web3Auth = web3Auth else {
			lastError = .networkError("Web3Auth not initialized")
			return
		}
		
		Task {
			await MainActor.run {
				isLoading = true
			}
			
			do {
				let result = try await web3Auth.login(
					W3ALoginParams(
						loginProvider: .EMAIL_PASSWORDLESS,
						extraLoginOptions: ExtraLoginOptions(
							login_hint: email
						)
					)
				)
				
				await MainActor.run {
					user = result
					isLoggedIn = true
					updateUserInfo()
					isLoading = false
				}
			} catch {
				await MainActor.run {
					lastError = .networkError("Email login failed: \(error.localizedDescription)")
					isLoading = false
				}
			}
		}
		#else
		lastError = .networkError("Web3Auth SDK not linked. Add via SPM and import in this target.")
		#endif
	}
	
	func logout() {
		#if canImport(Web3Auth)
		Task {
			do {
				try await web3Auth?.logout()
				await MainActor.run {
					isLoggedIn = false
					address = nil
					displayName = nil
					user = nil
				}
			} catch {
				await MainActor.run {
					lastError = .networkError("Logout failed: \(error.localizedDescription)")
				}
			}
		}
		#else
		isLoggedIn = false
		address = nil
		displayName = nil
		user = nil
		#endif
	}
	
	/// Forward incoming URL callbacks for Web3Auth to process.
	@discardableResult
	func handleURL(_ url: URL) -> Bool {
		#if canImport(Web3Auth)
		// Web3Auth handles URL callbacks automatically in the SDK
		// No manual handling needed for the current implementation
		return false
		#else
		return false
		#endif
	}
	
	// MARK: - Private Helpers
	
	private func updateUserInfo() {
		guard let user = user else { return }
		
		// Extract address from private key
		if let privKey = user.privKey {
			do {
				// Convert private key to Data and derive address
				guard let privKeyData = Data(hexString: privKey) else {
					address = nil
					return
				}
				
				// Create Ethereum private key from data to get address
				let privateKey = try EthereumPrivateKey(privateKey: Array(privKeyData))
				address = privateKey.address.hex(eip55: true)
			} catch {
				// Fallback to using the first 40 characters of private key
				address = "0x" + String(privKey.prefix(40))
			}
		}
		
		displayName = user.userInfo?.name ?? user.userInfo?.email ?? "Web3Auth User"
	}
}
