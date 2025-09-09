//
//  ProximityManager.swift
//  airmeishi
//
//  Manages proximity-based sharing using Multipeer Connectivity for device discovery and sharing
//

import Foundation
import MultipeerConnectivity
import Combine
import UIKit

/// Protocol for proximity sharing operations
protocol ProximityManagerProtocol {
    func startAdvertising(with card: BusinessCard, sharingLevel: SharingLevel)
    func stopAdvertising()
    func startBrowsing()
    func stopBrowsing()
    func sendCard(_ card: BusinessCard, to peer: MCPeerID, sharingLevel: SharingLevel)
    func disconnect()
}

/// Manages proximity-based sharing using Multipeer Connectivity
class ProximityManager: NSObject, ProximityManagerProtocol, ObservableObject {
    static let shared = ProximityManager()
    
    // MARK: - Published Properties
    @Published private(set) var isAdvertising = false
    @Published private(set) var isBrowsing = false
    @Published private(set) var nearbyPeers: [ProximityPeer] = []
    @Published private(set) var connectionStatus: ProximityConnectionStatus = .disconnected
    @Published private(set) var lastError: CardError?
    @Published private(set) var receivedCards: [BusinessCard] = []
    
    // MARK: - Private Properties
    private let serviceType = "airmeishi-share"
    private let maxPeers = 8
    
    private var session: MCSession
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    private var localPeerID: MCPeerID
    
    private var currentCard: BusinessCard?
    private var currentSharingLevel: SharingLevel = .professional
    
    @MainActor private let contactRepository = ContactRepository.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    override init() {
        // Create unique peer ID based on device
        let deviceName = UIDevice.current.name
        self.localPeerID = MCPeerID(displayName: deviceName)
        
        // Initialize session
        self.session = MCSession(peer: localPeerID, securityIdentity: nil, encryptionPreference: .required)
        
        super.init()
        
        session.delegate = self
        setupNotifications()
    }
    
    deinit {
        disconnect()
    }
    
    // MARK: - Public Methods
    
    /// Start advertising the current business card for proximity sharing
    func startAdvertising(with card: BusinessCard, sharingLevel: SharingLevel) {
        guard !isAdvertising else { return }
        
        currentCard = card
        currentSharingLevel = sharingLevel
        
        // Create discovery info with card preview
        let discoveryInfo = createDiscoveryInfo(for: card, level: sharingLevel)
        
        advertiser = MCNearbyServiceAdvertiser(
            peer: localPeerID,
            discoveryInfo: discoveryInfo,
            serviceType: serviceType
        )
        
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        
        isAdvertising = true
        connectionStatus = .advertising
        
        print("Started advertising business card: \(card.name)")
    }
    
    /// Stop advertising
    func stopAdvertising() {
        guard isAdvertising else { return }
        
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        
        isAdvertising = false
        currentCard = nil
        
        updateConnectionStatus()
        
        print("Stopped advertising")
    }
    
    /// Start browsing for nearby peers
    func startBrowsing() {
        guard !isBrowsing else { return }
        
        browser = MCNearbyServiceBrowser(peer: localPeerID, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        
        isBrowsing = true
        connectionStatus = .browsing
        
        print("Started browsing for nearby peers")
    }
    
    /// Stop browsing
    func stopBrowsing() {
        guard isBrowsing else { return }
        
        browser?.stopBrowsingForPeers()
        browser = nil
        
        isBrowsing = false
        nearbyPeers.removeAll()
        
        updateConnectionStatus()
        
        print("Stopped browsing")
    }
    
    /// Send business card to a specific peer
    func sendCard(_ card: BusinessCard, to peer: MCPeerID, sharingLevel: SharingLevel) {
        guard session.connectedPeers.contains(peer) else {
            lastError = .sharingError("Peer is not connected")
            return
        }
        
        do {
            // Filter card based on sharing level
            let filteredCard = card.filteredCard(for: sharingLevel)
            
            // Create sharing payload
            let payload = ProximitySharingPayload(
                card: filteredCard,
                sharingLevel: sharingLevel,
                timestamp: Date(),
                senderID: localPeerID.displayName
            )
            
            let data = try JSONEncoder().encode(payload)
            
            try session.send(data, toPeers: [peer], with: .reliable)
            
            print("Sent business card to \(peer.displayName)")
            
        } catch {
            lastError = .sharingError("Failed to send card: \(error.localizedDescription)")
            print("Failed to send card: \(error)")
        }
    }
    
    /// Disconnect from all peers and stop all services
    func disconnect() {
        stopAdvertising()
        stopBrowsing()
        
        session.disconnect()
        nearbyPeers.removeAll()
        connectionStatus = .disconnected
        
        print("Disconnected from all peers")
    }
    
    /// Get current sharing status
    func getSharingStatus() -> ProximitySharingStatus {
        return ProximitySharingStatus(
            isAdvertising: isAdvertising,
            isBrowsing: isBrowsing,
            connectedPeersCount: session.connectedPeers.count,
            nearbyPeersCount: nearbyPeers.count,
            currentCard: currentCard,
            sharingLevel: currentSharingLevel
        )
    }
    
    /// Connect to a specific peer
    func connectToPeer(_ peer: ProximityPeer) {
        guard let browser = browser else {
            lastError = .sharingError("Browser not available")
            return
        }
        
        browser.invitePeer(peer.peerID, to: session, withContext: nil, timeout: 30)
        
        // Update peer status
        if let index = nearbyPeers.firstIndex(where: { $0.id == peer.id }) {
            nearbyPeers[index].status = .connecting
        }
        
        print("Connecting to peer: \(peer.name)")
    }
    
    /// Clear received cards
    func clearReceivedCards() {
        receivedCards.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func createDiscoveryInfo(for card: BusinessCard, level: SharingLevel) -> [String: String] {
        let filteredCard = card.filteredCard(for: level)
        
        var info: [String: String] = [:]
        info["name"] = filteredCard.name
        
        if let title = filteredCard.title, !title.isEmpty {
            info["title"] = title
        }
        
        if let company = filteredCard.company, !company.isEmpty {
            info["company"] = company
        }
        
        info["level"] = level.rawValue
        info["timestamp"] = String(Int(Date().timeIntervalSince1970))
        
        return info
    }
    
    private func updateConnectionStatus() {
        if isAdvertising && isBrowsing {
            connectionStatus = .advertisingAndBrowsing
        } else if isAdvertising {
            connectionStatus = .advertising
        } else if isBrowsing {
            connectionStatus = .browsing
        } else if !session.connectedPeers.isEmpty {
            connectionStatus = .connected
        } else {
            connectionStatus = .disconnected
        }
    }
    
    private func setupNotifications() {
        // Listen for app state changes
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.stopAdvertising()
                self?.stopBrowsing()
            }
            .store(in: &cancellables)
    }
    
    private func handleReceivedCard(_ card: BusinessCard, from senderName: String) {
        // Add to received cards
        receivedCards.append(card)
        
        // Save to contact repository on main actor
        Task { @MainActor in
            let contact = Contact(
                businessCard: card,
                source: .proximity,
                verificationStatus: .unverified
            )
            
            let result = contactRepository.addContact(contact)
            
            switch result {
            case .success:
                print("Received and saved business card from \(senderName)")
            case .failure(let error):
                print("Failed to save received card: \(error)")
                self.lastError = error
            }
        }
    }
}

// MARK: - MCSessionDelegate

extension ProximityManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Update peer status in nearby peers list
            if let index = self.nearbyPeers.firstIndex(where: { $0.peerID == peerID }) {
                switch state {
                case .connected:
                    self.nearbyPeers[index].status = .connected
                case .connecting:
                    self.nearbyPeers[index].status = .connecting
                case .notConnected:
                    self.nearbyPeers[index].status = .disconnected
                @unknown default:
                    break
                }
            }
            
            self.updateConnectionStatus()
            
            print("Peer \(peerID.displayName) changed state to: \(state)")
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        do {
            let payload = try JSONDecoder().decode(ProximitySharingPayload.self, from: data)
            
            DispatchQueue.main.async { [weak self] in
                self?.handleReceivedCard(payload.card, from: payload.senderID)
            }
            
        } catch {
            print("Failed to decode received data: \(error)")
            DispatchQueue.main.async { [weak self] in
                self?.lastError = .sharingError("Failed to decode received card")
            }
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // Not used for business card sharing
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // Not used for business card sharing
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        // Not used for business card sharing
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension ProximityManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        
        // Auto-accept invitations (in production, you might want user confirmation)
        invitationHandler(true, session)
        
        print("Received invitation from \(peerID.displayName)")
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.lastError = .sharingError("Failed to start advertising: \(error.localizedDescription)")
            self?.isAdvertising = false
        }
        
        print("Failed to start advertising: \(error)")
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension ProximityManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        
        let peer = ProximityPeer(
            peerID: peerID,
            discoveryInfo: info ?? [:],
            discoveredAt: Date()
        )
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Add peer if not already in list
            if !self.nearbyPeers.contains(where: { $0.peerID == peerID }) {
                self.nearbyPeers.append(peer)
                print("Found peer: \(peerID.displayName)")
            }
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        DispatchQueue.main.async { [weak self] in
            self?.nearbyPeers.removeAll { $0.peerID == peerID }
            print("Lost peer: \(peerID.displayName)")
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.lastError = .sharingError("Failed to start browsing: \(error.localizedDescription)")
            self?.isBrowsing = false
        }
        
        print("Failed to start browsing: \(error)")
    }
}

// MARK: - Supporting Types

/// Represents a nearby peer discovered through Multipeer Connectivity
struct ProximityPeer: Identifiable, Equatable {
    let id = UUID()
    let peerID: MCPeerID
    let discoveryInfo: [String: String]
    let discoveredAt: Date
    var status: ProximityPeerStatus = .disconnected
    
    var name: String {
        return peerID.displayName
    }
    
    var cardName: String? {
        return discoveryInfo["name"]
    }
    
    var cardTitle: String? {
        return discoveryInfo["title"]
    }
    
    var cardCompany: String? {
        return discoveryInfo["company"]
    }
    
    var sharingLevel: SharingLevel {
        if let levelString = discoveryInfo["level"],
           let level = SharingLevel(rawValue: levelString) {
            return level
        }
        return .professional
    }
    
    static func == (lhs: ProximityPeer, rhs: ProximityPeer) -> Bool {
        return lhs.peerID == rhs.peerID
    }
}

/// Status of a proximity peer connection
enum ProximityPeerStatus: String, CaseIterable {
    case disconnected = "Disconnected"
    case connecting = "Connecting"
    case connected = "Connected"
    
    var systemImageName: String {
        switch self {
        case .disconnected: return "circle"
        case .connecting: return "circle.dotted"
        case .connected: return "circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .disconnected: return "gray"
        case .connecting: return "orange"
        case .connected: return "green"
        }
    }
}

/// Overall connection status for proximity sharing
enum ProximityConnectionStatus: String, CaseIterable {
    case disconnected = "Disconnected"
    case advertising = "Advertising"
    case browsing = "Browsing"
    case advertisingAndBrowsing = "Advertising & Browsing"
    case connected = "Connected"
    
    var displayName: String {
        return self.rawValue
    }
    
    var systemImageName: String {
        switch self {
        case .disconnected: return "wifi.slash"
        case .advertising: return "dot.radiowaves.left.and.right"
        case .browsing: return "magnifyingglass"
        case .advertisingAndBrowsing: return "dot.radiowaves.up.forward"
        case .connected: return "wifi"
        }
    }
}

/// Payload structure for proximity sharing
struct ProximitySharingPayload: Codable {
    let card: BusinessCard
    let sharingLevel: SharingLevel
    let timestamp: Date
    let senderID: String
}

/// Current sharing status information
struct ProximitySharingStatus {
    let isAdvertising: Bool
    let isBrowsing: Bool
    let connectedPeersCount: Int
    let nearbyPeersCount: Int
    let currentCard: BusinessCard?
    let sharingLevel: SharingLevel
}