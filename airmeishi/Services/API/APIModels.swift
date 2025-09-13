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

// MARK: - ENS

struct ENSResponse: Codable {
    let address: String?
    let name: String?
}

// MARK: - Groups

struct GroupCreateRequest: Codable {
    let name: String
    let ensName: String?
    let ensSignature: String?
}

struct GroupCreateResponse: Codable {
    let groupId: String
    let zkRoot: String
}

struct GroupRootResponse: Codable {
    let zkRoot: String
    let blockNumber: Int
}

struct AddMemberRequest: Codable {
    let commitment: String
    let signature: String
}

struct AddMemberResponse: Codable {
    let newRoot: String
    let index: Int
}

struct RevokeMemberRequest: Codable {
    let memberIndex: Int
    let nullifier: String
    let signature: String
}

struct RevokeMemberResponse: Codable {
    let newRoot: String
    let revokedAt: String
}

// MARK: - Shoutouts

struct CreateShoutoutRequest: Codable {
    let content: String
    let media: [URL]?
    let tags: [String]?
    let zkProof: String?
    let author: String?
}

struct CreateShoutoutResponse: Codable {
    let id: String
    let timestamp: Double
}

struct Shoutout: Codable {
    let id: String
    let content: String
    let author: String
    let timestamp: Double
    let media: [String]
    let tags: [String]
}


