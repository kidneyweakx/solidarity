//
//  AuthService.swift
//  airmeishi
//
//  Authentication endpoints
//

import Foundation

class AuthService {
    private let client: APIClient
    
    init(client: APIClient = .shared) {
        self.client = client
    }
    
    /// POST /auth/auth/verify
    func verifySignature(_ payload: AuthVerifyRequest) async -> CardResult<String> {
        let result: CardResult<AuthResponse> = await client.request(
            path: "auth/auth/verify",
            method: .POST,
            body: payload,
            decodeAs: AuthResponse.self
        )
        switch result {
        case .success(let auth):
            let storeResult = APIAuthManager.shared.setToken(auth.token)
            switch storeResult {
            case .success:
                return .success(auth.token)
            case .failure(let error):
                return .failure(error)
            }
        case .failure(let error):
            return .failure(error)
        }
    }
}


