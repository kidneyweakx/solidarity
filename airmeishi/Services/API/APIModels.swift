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

// MARK: - Groups (only two endpoints: /group and /group/{name}/member)

struct CreateGroupRequest: Codable {
    let name: String
    let members: [String]?
    let ownerAddress: String?
    let skipEns: Bool?
}

struct CreateGroupResponse: Codable {
    let name: String
    let members: [String]
    let tree_root: String
    let member_count: Int
    let ens_domain: String?
    let ens_owner_address: String?
    let ens_registration_tx: String?
    let ens_transfer_tx: String?
    let ens_status: String?
    let ens_error: String?
    let created_at: String?
}

struct AddGroupMemberRequest: Codable {
    let userId: String
    let ownerAddress: String
}

struct AddGroupMemberResponse: Codable {
    let name: String
    let members: [String]
    let tree_root: String
    let member_count: Int
    let added_member: String
    let updated_at: String
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


