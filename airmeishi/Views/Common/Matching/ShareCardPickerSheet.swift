//
//  ShareCardPickerSheet.swift
//  airmeishi
//
//  Sheet to start/stop advertising a selected business card at a chosen privacy level.
//

import SwiftUI

struct ShareCardPickerSheet: View {
    let cards: [BusinessCard]
    let onStart: (BusinessCard, SharingLevel) -> Void
    let onStop: () -> Void
    let isAdvertising: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCardId: UUID? = nil
    @State private var level: SharingLevel = .professional
    
    var body: some View {
        NavigationView {
            Form {
                Section("Card") {
                    Picker("Business Card", selection: $selectedCardId) {
                        ForEach(cards) { card in
                            Text(card.name).tag(Optional(card.id))
                        }
                    }
                }
                Section("Privacy Level") {
                    Picker("Level", selection: $level) {
                        ForEach(SharingLevel.allCases, id: \.self) { lvl in
                            Text(lvl.displayName).tag(lvl)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                if let card = cards.first(where: { $0.id == selectedCardId }) {
                    Section("Preview") {
                        BusinessCardPreview(businessCard: card.filteredCard(for: level))
                    }
                }
            }
            .navigationTitle("Share Card")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isAdvertising {
                        Button("Stop") { onStop(); dismiss() }
                    } else {
                        Button("Start") {
                            if let id = selectedCardId, let card = cards.first(where: { $0.id == id }) {
                                onStart(card, level)
                                dismiss()
                            }
                        }
                        .disabled(selectedCardId == nil)
                    }
                }
            }
        }
        .onAppear { if selectedCardId == nil { selectedCardId = cards.first?.id } }
    }
}


