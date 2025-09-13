//
//  IDView.swift
//  airmeishi
//
//  Identity view with ring interaction for Semaphore identity/group and proof generation
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
    @State private var isWorking: Bool = false
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String?
    @State private var latestProof: String?
    @State private var isEditingProof: Bool = false
    @State private var proofDraft: String = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                GeometryReader { geo in
                    ZStack {
                        let base = min(geo.size.width, geo.size.height)
                        // Indices chosen so that 1 = inner, 3 = outer to light from inner -> outer
                        ringView(size: base * 0.80, index: 3)
                        ringView(size: base * 0.62, index: 2)
                        ringView(size: base * 0.46, index: 1)
                        centerButton(size: base * 0.36)
                            .onTapGesture(count: 3) {
                                isEditingProof.toggle()
                                if isEditingProof, let proof = latestProof { proofDraft = proof }
                            }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(height: 360)

                identityPanel()
                verificationPanel()
            }
            .navigationTitle("ID")
            .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        NavigationLink {
                            GroupManagementView()
                            } label: {
                            Image(systemName: "person.3")
                            }
                            Button {
                                showingSettings = true
                            } label: {
                                Image(systemName: "gear")
                            }
                        }
                    }
                }
        }
        .sheet(isPresented: $showingSettings) {
            NavigationStack { ZKIdentitySettingsView() }
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Unknown error")
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
                .fill(
                    identityCommitment.isEmpty
                    ? LinearGradient(colors: [.accentColor.opacity(0.9), .accentColor.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    : LinearGradient(colors: [.green.opacity(0.95), .blue.opacity(0.75)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .frame(width: size, height: size)
                .shadow(color: .accentColor.opacity(isPressing ? 0.6 : 0.25), radius: isPressing ? 20 : 10)
                .overlay(
                    VStack(spacing: 6) {
                        Text("ID")
                            .font(.title2.weight(.bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.35), radius: 3, x: 0, y: 1)
                        if let status = proofStatus {
                            Text(status)
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.25))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        } else if !identityCommitment.isEmpty {
                            VStack(spacing: 4) {
                                Text("Commitment")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.9))
                                Text(shortCommitment(identityCommitment))
                                    .font(.caption.monospaced())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.black.opacity(0.20))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                Text("Tap to copy")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        } else {
                            Text("Tap: ID + Proof\nHold: Create Group")
                                .font(.caption2)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.20))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
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
        if isWorking { return }
        isWorking = true
        proofStatus = "Working..."
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                if identityCommitment.isEmpty {
                    // First time: create ID and show commitment; do not regenerate later
                    let bundle = try idm.loadOrCreateIdentity()
                    DispatchQueue.main.async {
                        identityCommitment = bundle.commitment
                        proofStatus = bundle.commitment.isEmpty ? "ID created (pending)" : "ID created"
                        isWorking = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { proofStatus = nil }
                    }
                    if !group.members.contains(bundle.commitment) { group.addMember(bundle.commitment) }
                } else {
                    // Already have ID: copy commitment
                    #if canImport(UIKit)
                    DispatchQueue.main.async {
                        UIPasteboard.general.string = identityCommitment
                        proofStatus = "Copied"
                        isWorking = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { proofStatus = nil }
                    }
                    #else
                    DispatchQueue.main.async {
                        proofStatus = "Commitment ready"
                        isWorking = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { proofStatus = nil }
                    }
                    #endif
                }
            } catch {
                ZKLog.error("Error on tapAction: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                    proofStatus = "Error: \(error.localizedDescription)"
                    isWorking = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) { proofStatus = nil }
                }
            }
        }
    }

    private func longPressAction() {
        if isWorking { return }
        isWorking = true
        proofStatus = "Working..."
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let bundle = try idm.loadOrCreateIdentity()
                DispatchQueue.main.async { identityCommitment = bundle.commitment }
                group.setMembers([bundle.commitment])
                print("[Semaphore] Group initialized with 1 member (self). Commitment: \(bundle.commitment)")
                DispatchQueue.main.async {
                    proofStatus = "Group created"
                    isWorking = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { proofStatus = nil }
                }
            } catch {
                ZKLog.error("Error on longPressAction: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                    proofStatus = "Error: \(error.localizedDescription)"
                    isWorking = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) { proofStatus = nil }
                }
            }
        }
    }

    // MARK: - Logging helpers

    private func logProofInputs(commitment: String, members: [String], message: String, scope: String, depth: Int) {
        print("====== [Semaphore] Proof Inputs ======")
        print("Identity commitment: \(commitment)")
        print("Group members count: \(members.count)")
        if members.isEmpty {
            print("Members: []")
        } else {
            let preview = members.prefix(5).joined(separator: ", ")
            print("Members preview (up to 5): [\(preview)]")
        }
        print("Message: \(message)")
        print("Scope: \(scope)")
        print("Merkle depth: \(depth)")
        print("=====================================")
    }

    private func logProofOutput(_ proof: String) {
        print("====== [Semaphore] Proof Output ======")
        if let pretty = prettyPrintJSON(proof) {
            print(pretty)
        } else {
            let snippet = proof.prefix(600)
            print(String(snippet))
            if proof.count > 600 { print("... (truncated) ...") }
        }
        print("=====================================")
    }

    private func prettyPrintJSON(_ jsonString: String) -> String? {
        guard let data = jsonString.data(using: .utf8) else { return nil }
        guard let obj = try? JSONSerialization.jsonObject(with: data, options: []) else { return nil }
        guard let prettyData = try? JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .withoutEscapingSlashes]) else { return nil }
        return String(data: prettyData, encoding: .utf8)
    }

    private func shortCommitment(_ c: String) -> String {
        if c.count <= 12 { return c }
        let start = c.prefix(6)
        let end = c.suffix(6)
        return String(start) + "…" + String(end)
    }

    // MARK: - Verification UI/Action

    @ViewBuilder
    private func verificationPanel() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Verification")
                    .font(.headline)
                Spacer()
                Button("Verify Proof") { verifyProofAction() }
                    .buttonStyle(.borderedProminent)
                    .disabled(!SemaphoreIdentityManager.proofsSupported || latestProof == nil || isWorking)
            }
            if isEditingProof {
                Text("Editing mode (triple tap center to toggle)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextEditor(text: $proofDraft)
                    .font(.footnote)
                    .frame(minHeight: 120, maxHeight: 180)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(uiColor: .secondarySystemBackground)))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.2)))
            } else if let proof = latestProof {
                let display = prettyPrintJSON(proof) ?? String(proof.prefix(600))
                ScrollView {
                    Text(display)
                        .font(.footnote)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 140)
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(uiColor: .secondarySystemBackground)))
            } else {
                Text("No proof yet. Tap the center to generate.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Identity panel

    @ViewBuilder
    private func identityPanel() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Your ID")
                    .font(.headline)
                Spacer()
                if !identityCommitment.isEmpty {
                    Button {
                        #if canImport(UIKit)
                        UIPasteboard.general.string = identityCommitment
                        #endif
                        proofStatus = "Copied"
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { proofStatus = nil }
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)
                }
            }
            if identityCommitment.isEmpty {
                Text("No ID yet. Tap the center to create your identity.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text(shortCommitment(identityCommitment))
                        .font(.callout.monospaced())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(uiColor: .secondarySystemBackground)))
                    DisclosureGroup("Show full") {
                        ScrollView(.horizontal, showsIndicators: true) {
                            Text(identityCommitment)
                                .font(.footnote.monospaced())
                                .textSelection(.enabled)
                                .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    private func verifyProofAction() {
        let proof: String
        if isEditingProof {
            proof = proofDraft
        } else {
            guard let p = latestProof else { return }
            proof = p
        }
        if isWorking { return }
        if !SemaphoreIdentityManager.proofsSupported {
            proofStatus = "Verification not available"
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { proofStatus = nil }
            return
        }
        isWorking = true
        proofStatus = "Verifying..."
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let ok = try idm.verifyProof(proof)
                print("[Semaphore] Verify result: \(ok)")
                DispatchQueue.main.async {
                    proofStatus = ok ? "Proof valid" : "Proof invalid"
                    isWorking = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { proofStatus = nil }
                }
            } catch {
                print("[Semaphore] Verify error: \(error)")
                DispatchQueue.main.async {
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                    proofStatus = "Error: \(error.localizedDescription)"
                    isWorking = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) { proofStatus = nil }
                }
            }
        }
    }
}

#Preview {
    IDView()
}


