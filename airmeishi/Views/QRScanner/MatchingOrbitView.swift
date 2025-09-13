//
//  MatchingOrbitView.swift
//  airmeishi
//
//  Lightweight orbit animation used on the simplified Match screen
//

import SwiftUI

struct MatchingOrbitView: View {
    @StateObject private var proximityManager = ProximityManager.shared
    @State private var rotateOuter: Bool = false
    @State private var rotateMiddle: Bool = false
    @State private var rotateInner: Bool = false
    @State private var showNearbySheet: Bool = false
    @State private var showPeerCardSheet: Bool = false
    
    var body: some View {
        ZStack {
            // Concentric rings
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 2)
                .padding(4)
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 2)
                .padding(44)
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 2)
                .padding(84)
            
            // Center planet (tappable)
            Button(action: { showNearbySheet = true }) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.25))
                        .frame(width: 96, height: 96)
                        .overlay(
                            Circle().stroke(Color.white.opacity(0.35), lineWidth: 1)
                        )
                    VStack(spacing: 2) {
                        Text("Nearby")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                        Text("\(proximityManager.nearbyPeers.count)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Orbiting satellites
            orbit(radiusPadding: 4, size: 18)
                .rotationEffect(.degrees(rotateOuter ? 360 : 0))
                .animation(.linear(duration: 14).repeatForever(autoreverses: false), value: rotateOuter)
            orbit(radiusPadding: 44, size: 16)
                .rotationEffect(.degrees(rotateMiddle ? -360 : 0))
                .animation(.linear(duration: 10).repeatForever(autoreverses: false), value: rotateMiddle)
            orbit(radiusPadding: 84, size: 14)
                .rotationEffect(.degrees(rotateInner ? 360 : 0))
                .animation(.linear(duration: 7).repeatForever(autoreverses: false), value: rotateInner)
        }
        // Top overlay removed; center planet handles interactions
        .onAppear {
            rotateOuter = true
            rotateMiddle = true
            rotateInner = true
        }
        .sheet(isPresented: $showNearbySheet) {
            NearbyPeersSheet(
                peers: proximityManager.nearbyPeers,
                connectedCount: proximityManager.getSharingStatus().connectedPeersCount,
                onViewLatestCard: {
                    if proximityManager.receivedCards.last != nil {
                        showPeerCardSheet = true
                    }
                }
            )
        }
        .sheet(isPresented: $showPeerCardSheet) {
            if let card = proximityManager.receivedCards.last {
                ReceivedCardView(card: card)
            } else {
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                    Text("Waiting for peer's card...")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                .padding()
            }
        }
    }
    
    private func orbit(radiusPadding: CGFloat, size: CGFloat) -> some View {
        GeometryReader { proxy in
            let frame = proxy.size
            let minSide = min(frame.width, frame.height)
            let radius = (minSide / 2) - radiusPadding
            ZStack {
                satellite(size: size)
                    .offset(x: radius, y: 0)
                satellite(size: size)
                    .offset(x: 0, y: radius)
                satellite(size: size)
                    .offset(x: -radius * 0.9, y: -radius * 0.4)
                satellite(size: size)
                    .offset(x: radius * 0.4, y: -radius * 0.85)
            }
            .frame(width: frame.width, height: frame.height)
        }
    }
    
    private func satellite(size: CGFloat) -> some View {
        Circle()
            .fill(Color.white.opacity(0.8))
            .frame(width: size, height: size)
    }
}

// MARK: - Nearby Peers Sheet

private struct NearbyPeersSheet: View {
    let peers: [ProximityPeer]
    let connectedCount: Int
    let onViewLatestCard: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if peers.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "person.2")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.secondary)
                        Text("No nearby peers yet")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(UIColor.systemBackground))
                } else {
                    List(peers) { peer in
                        HStack(alignment: .center, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(peer.cardName ?? peer.name)
                                    .font(.headline)
                                HStack(spacing: 8) {
                                    if let title = peer.cardTitle { Text(title).font(.subheadline).foregroundColor(.secondary) }
                                    if let company = peer.cardCompany { Text(company).font(.subheadline).foregroundColor(.secondary) }
                                }
                                Text(peer.status.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if let v = peer.verification {
                                HStack(spacing: 6) {
                                    Image(systemName: v.systemImageName)
                                        .foregroundColor(v == .verified ? .green : (v == .failed ? .red : .orange))
                                    Text(v.displayName)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .listStyle(.insetGrouped)
                }
                if connectedCount > 0 {
                    Button(action: onViewLatestCard) {
                        HStack(spacing: 8) {
                            Image(systemName: "person.crop.circle.badge.checkmark")
                            Text("View latest received card")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
            }
            .navigationTitle("Nearby Peers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ZStack { Color.black.ignoresSafeArea(); MatchingOrbitView().frame(width: 300, height: 300) }
        .preferredColorScheme(.dark)
}


