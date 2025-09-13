//
//  ENSService.swift
//  airmeishi
//
//  ENS resolve and reverse lookups
//

import Foundation

class ENSService {
    private let client: APIClient
    
    init(client: APIClient = .shared) {
        self.client = client
    }
    
    /// GET /ens/ens/resolve?name=...
    func resolve(name: String) async -> CardResult<ENSResponse> {
        return await client.request(
            path: "ens/ens/resolve",
            queryItems: [URLQueryItem(name: "name", value: name)],
            includeAuth: false,
            decodeAs: ENSResponse.self
        )
    }
    
    /// GET /ens/ens/reverse?address=0x...
    func reverse(address: String) async -> CardResult<ENSResponse> {
        return await client.request(
            path: "ens/ens/reverse",
            queryItems: [URLQueryItem(name: "address", value: address)],
            includeAuth: false,
            decodeAs: ENSResponse.self
        )
    }
}


