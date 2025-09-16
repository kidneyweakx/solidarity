//
//  APIModels.swift
//  airmeishi
//
//  Codable models matching backend OpenAPI
//

import Foundation

// MARK: - Auth

struct AuthVerifyRequest: Codable {
    let address: String
    let message: String
    let signature: String
}

struct AuthResponse: Codable {
    let token: String
}

// MARK: - Common Error

struct ErrorResponse: Codable {
    let message: String
}
