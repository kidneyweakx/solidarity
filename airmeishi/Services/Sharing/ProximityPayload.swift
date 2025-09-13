//
//  ProximityPayload.swift
//  airmeishi
//
//  Defines the payload used for proximity-based sharing, including ZK info.
//

import Foundation

struct ProximitySharingPayload: Codable {
    let card: BusinessCard
    let sharingLevel: SharingLevel
    let timestamp: Date
    let senderID: String
    let shareId: UUID
    let issuerCommitment: String?
    let issuerProof: String?
    let sdProof: SelectiveDisclosureProof?
}


