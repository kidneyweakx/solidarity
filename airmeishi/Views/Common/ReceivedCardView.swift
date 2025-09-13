import SwiftUI

struct ReceivedCardView: View {
    let card: BusinessCard
    @Environment(\.dismiss) private var dismiss
    @State private var isLightningAnimating = false
    @State private var showingShoutoutGallery = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dark gradient background with lightning effect
                LinearGradient(
                    colors: [
                        Color.black,
                        Color.green.opacity(0.1),
                        Color.blue.opacity(0.05),
                        Color.black
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Lightning success indicator
                        VStack(spacing: 16) {
                            ZStack {
                                // Lightning ring
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [.green, .yellow, .green],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 4
                                    )
                                    .frame(width: 100, height: 100)
                                    .scaleEffect(isLightningAnimating ? 1.1 : 1.0)
                                    .animation(
                                        .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                                        value: isLightningAnimating
                                    )
                                
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.yellow)
                                    .scaleEffect(isLightningAnimating ? 1.2 : 1.0)
                                    .animation(
                                        .easeInOut(duration: 0.5).repeatForever(autoreverses: true),
                                        value: isLightningAnimating
                                    )
                            }
                            
                            VStack(spacing: 8) {
                                Text("Lightning Card Received! ⚡")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text("Business card has been saved to your lightning gallery")
                                    .font(.body)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding()
                        
                        // Card preview with lightning theme
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Card Details")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Image(systemName: "bolt.circle.fill")
                                    .foregroundColor(.yellow)
                                    .font(.title2)
                                    .scaleEffect(isLightningAnimating ? 1.2 : 1.0)
                                    .animation(
                                        .easeInOut(duration: 0.5).repeatForever(autoreverses: true),
                                        value: isLightningAnimating
                                    )
                            }
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text(card.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                if let title = card.title {
                                    Text(title)
                                        .font(.headline)
                                        .foregroundColor(.yellow)
                                }
                                
                                if let company = card.company {
                                    Text(company)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                
                                if let email = card.email {
                                    HStack {
                                        Image(systemName: "envelope.fill")
                                            .foregroundColor(.blue)
                                        Text(email)
                                            .font(.subheadline)
                                            .foregroundColor(.blue)
                                    }
                                }
                                
                                if let phone = card.phone {
                                    HStack {
                                        Image(systemName: "phone.fill")
                                            .foregroundColor(.green)
                                        Text(phone)
                                            .font(.subheadline)
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                                )
                        )
                        
                        // Lightning action buttons
                        VStack(spacing: 12) {
                            Button(action: { showingShoutoutGallery = true }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "bolt.fill")
                                        .font(.title2)
                                        .scaleEffect(isLightningAnimating ? 1.3 : 1.0)
                                        .animation(
                                            .easeInOut(duration: 0.3).repeatForever(autoreverses: true),
                                            value: isLightningAnimating
                                        )
                                    
                                    Text("View in Lightning Gallery")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(
                                            LinearGradient(
                                                colors: [.yellow, .orange, .red],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .shadow(color: .yellow.opacity(0.5), radius: 10, x: 0, y: 0)
                                )
                            }
                            
                            Button(action: { dismiss() }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle")
                                        .font(.title3)
                                    Text("Continue")
                                        .font(.headline)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                )
                            }
                        }
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("Lightning Received")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .onAppear {
                isLightningAnimating = true
            }
            .sheet(isPresented: $showingShoutoutGallery) {
                ShoutoutView()
            }
        }
        .preferredColorScheme(.dark)
    }
}
