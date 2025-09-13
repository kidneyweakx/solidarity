//
//  ProximityEvents.swift
//  airmeishi
//
//  Global notification names for proximity matching so multiple views can react.
//

import Foundation

extension Notification.Name {
    static let matchingPeerListUpdated = Notification.Name("matchingPeerListUpdated")
    static let matchingConnectionStatusChanged = Notification.Name("matchingConnectionStatusChanged")
    static let matchingReceivedCard = Notification.Name("matchingReceivedCard")
    static let matchingError = Notification.Name("matchingError")
}

enum ProximityEventKey {
    static let peers = "peers"
    static let status = "status"
    static let card = "card"
    static let error = "error"
}


