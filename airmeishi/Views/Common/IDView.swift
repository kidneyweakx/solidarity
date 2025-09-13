//
//  IDView.swift
//  airmeishi
//
//  Identity & Events: shows verified participation history and lets user import .eml
//

import SwiftUI
import UniformTypeIdentifiers

enum EventLayoutMode: String, CaseIterable, Identifiable {
    case list
    case grid
    case timeline
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .list: return "List"
        case .grid: return "Grid"
        case .timeline: return "Timeline"
        }
    }
}

struct IDView: View {
    @StateObject private var idm = SemaphoreIdentityManager.shared
    @StateObject private var group = SemaphoreGroupManager.shared
    @State private var showingSettings = false
    @State private var identityCommitment: String = ""
    @State private var proofStatus: String?
    @State private var ringActiveCount: Int = 0
    @State private var isPressing: Bool = false
    @State private var ringTimer: Timer?

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    let base = min(geo.size.width, geo.size.height)
                    ringView(size: base * 0.80, index: 1)
                    ringView(size: base * 0.62, index: 2)
                    ringView(size: base * 0.46, index: 3)
                    centerButton(size: base * 0.36)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("ID")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            NavigationStack { ZKIdentitySettingsView() }
        }
        .onAppear {
            if let id = idm.getIdentity() { identityCommitment = id.commitment }
        }
    }

    private func ringView(size: CGFloat, index: Int) -> some View {
        Circle()
            .stroke(lineWidth: 8)
            .foregroundColor(index <= ringActiveCount ? Color.accentColor : Color.gray.opacity(0.2))
            .frame(width: size, height: size)
            .animation(.easeInOut(duration: 0.3), value: ringActiveCount)
    }

    private func centerButton(size: CGFloat) -> some View {
        let longPressDuration: Double = 3.0
        return ZStack {
            Circle()
                .fill(LinearGradient(colors: [.accentColor, .accentColor.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: size, height: size)
                .shadow(color: .accentColor.opacity(isPressing ? 0.6 : 0.25), radius: isPressing ? 20 : 10)
                .overlay(
                    VStack(spacing: 6) {
                        Text("ID")
                            .font(.title2.weight(.bold))
                            .foregroundColor(.white)
                        if let status = proofStatus {
                            Text(status)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.9))
                        } else if !identityCommitment.isEmpty {
                            Text("Commitment ready")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.9))
                        } else {
                            Text("Tap: ID + Proof\nHold: Create Group")
                                .font(.caption2)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                )
                .onTapGesture { tapAction() }
                .onLongPressGesture(minimumDuration: longPressDuration, maximumDistance: 50, pressing: { pressing in
                    isPressing = pressing
                    if pressing { startRingAnimation() } else { stopRingAnimation(reset: true) }
                }, perform: {
                    stopRingAnimation(reset: false)
                    longPressAction()
                })
        }
    }

    private func startRingAnimation() {
        ringActiveCount = 0
        ringTimer?.invalidate()
        ringTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            ringActiveCount = min(3, ringActiveCount + 1)
            if ringActiveCount >= 3 { timer.invalidate() }
        }
    }

    private func stopRingAnimation(reset: Bool) {
        ringTimer?.invalidate()
        ringTimer = nil
        if reset { ringActiveCount = 0 }
    }

    private func tapAction() {
        do {
            let bundle = try idm.loadOrCreateIdentity()
            identityCommitment = bundle.commitment
            if !group.members.contains(bundle.commitment) { group.addMember(bundle.commitment) }
            let proof = try idm.generateProof(groupCommitments: group.members, message: "hello", scope: "public", merkleDepth: 16)
            proofStatus = "Proof generated"
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { proofStatus = nil }
            _ = proof
        } catch {
            proofStatus = "Error: \(error.localizedDescription)"
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { proofStatus = nil }
        }
    }

    private func longPressAction() {
        do {
            let bundle = try idm.loadOrCreateIdentity()
            identityCommitment = bundle.commitment
            group.setMembers([bundle.commitment])
            proofStatus = "Group created"
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { proofStatus = nil }
        } catch {
            proofStatus = "Error: \(error.localizedDescription)"
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { proofStatus = nil }
        }
    }
}

#Preview {
    IDView()
}


