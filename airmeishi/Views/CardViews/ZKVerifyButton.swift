//
//  ZKVerifyButton.swift
//  airmeishi
//
//  A small reusable button to generate and verify a local SD proof
//

import SwiftUI

struct ZKVerifyButton: View {
    let businessCard: BusinessCard
    var sharingLevel: SharingLevel = .professional
    
    @State private var isVerifying = false
    @State private var verifyMessage: String?
    @State private var isValid: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button(action: verifyTapped) {
                if isVerifying {
                    ProgressView()
                } else {
                    Text("Verify ZK Proof")
                }
            }
            .buttonStyle(.bordered)
            .disabled(isVerifying)
            
            if let message = verifyMessage {
                Text(message)
                    .font(.caption)
                    .foregroundColor(isValid ? .green : .red)
            }
        }
    }
    
    private func verifyTapped() {
        isVerifying = true
        verifyMessage = nil
        let allowed = businessCard.sharingPreferences.fieldsForLevel(sharingLevel)
        let result = ProofGenerationManager.shared.generateSelectiveDisclosureProof(
            businessCard: businessCard,
            selectedFields: allowed,
            recipientId: nil
        )
        switch result {
        case .success(let proof):
            let vr = ProofGenerationManager.shared.verifySelectiveDisclosureProof(
                proof,
                expectedBusinessCardId: businessCard.id.uuidString
            )
            switch vr {
            case .success(let res):
                isValid = res.isValid
                verifyMessage = res.isValid ? "Proof valid" : "Invalid: \(res.reason)"
            case .failure(let err):
                isValid = false
                verifyMessage = err.localizedDescription
            }
        case .failure(let err):
            isValid = false
            verifyMessage = err.localizedDescription
        }
        isVerifying = false
    }
}


