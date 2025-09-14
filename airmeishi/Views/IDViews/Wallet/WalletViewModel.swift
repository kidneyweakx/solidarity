import Foundation
import Web3Auth

class WalletViewModel: ObservableObject {
    // Web3Auth state
    var web3Auth: Web3Auth?
    @Published var loggedIn: Bool = false
    @Published var user: Web3AuthState?
    @Published var isLoading = false
    @Published var navigationTitle: String = ""

    // Exposed user fields
    @Published var privateKey: String = ""
    @Published var ed25519PrivKey: String = ""
    @Published var userInfo: Web3AuthUserInfo?
    @Published var showError: Bool = false
    var errorMessage: String = ""

    // Config (follow sample defaults where possible)
    private var clientID: String = "BIrqtSxWou0y6Unpm_cFXcCSgqLXUldpnioD685xpd1ABC7cTDmOb6f_qA3MoM1naMeA-IWptPJ0wcNmgWzkCug"
    private var redirectUrl: String = "airmeishi://auth"
    private var network: Network = .sapphire_mainnet

    // MARK: - Setup
    func setup() async {
        guard web3Auth == nil else { return }
        await MainActor.run {
            isLoading = true
            navigationTitle = "Loading"
        }

        do {
            web3Auth = try await Web3Auth(W3AInitParams(
                clientId: clientID,
                network: network,
                redirectUrl: redirectUrl
            ))
        } catch {
            await MainActor.run {
                self.errorMessage = "Init failed: \(error.localizedDescription)"
                self.showError = true
            }
        }

        await MainActor.run {
            if let state = self.web3Auth?.state {
                self.user = state
                self.loggedIn = true
                self.handleUserDetails()
            }
            self.isLoading = false
            self.navigationTitle = self.loggedIn ? "UserInfo" : "SignIn"
        }
    }

    // MARK: - Login / Logout
    func login(provider: Web3AuthProvider) {
        Task {
            do {
                let result = try await web3Auth?.login(
                    W3ALoginParams(loginProvider: provider, mfaLevel: .DEFAULT, curve: .SECP256K1)
                )
                await MainActor.run {
                    self.user = result
                    self.loggedIn = true
                    self.handleUserDetails()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                }
            }
        }
    }

    func logout() {
        Task {
            do {
                try await web3Auth?.logout()
                await MainActor.run {
                    self.loggedIn = false
                    self.user = nil
                    self.privateKey = ""
                    self.ed25519PrivKey = ""
                    self.userInfo = nil
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                }
            }
        }
    }

    // MARK: - Helpers
    @MainActor func handleUserDetails() {
        guard let state = web3Auth?.state else { return }
        loggedIn = true
        user = state
        privateKey = state.privKey ?? ""
        ed25519PrivKey = state.ed25519PrivKey ?? ""
        userInfo = state.userInfo
    }
}