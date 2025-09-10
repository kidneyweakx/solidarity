import SwiftUI

struct ReceivedCardView: View {
    let card: BusinessCard
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Success indicator
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("Business Card Received!")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("The business card has been saved to your contacts")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    
                    // Card preview
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Card Details")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(card.name)
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            if let title = card.title {
                                Text(title)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            if let company = card.company {
                                Text(company)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            if let email = card.email {
                                Text(email)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            
                            if let phone = card.phone {
                                Text(phone)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Card Received")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
