import SwiftUI

struct ProximitySharingTabView: View {
    @State private var showingProximitySharing = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                VStack(spacing: 16) {
                    Image(systemName: "wave.3.right")
                        .font(.system(size: 80))
                        .foregroundColor(.green)
                    
                    Text("Proximity Sharing")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Share your business card with nearby people using iPhone touch or AirDrop")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                VStack(spacing: 12) {
                    Button(action: { showingProximitySharing = true }) {
                        HStack {
                            Image(systemName: "dot.radiowaves.left.and.right")
                            Text("Start Proximity Sharing")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                    }
                    
                    Text("Share via AirDrop, Multipeer Connectivity, or QR codes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Share")
        }
        .fullScreenCover(isPresented: $showingProximitySharing) {
            ProximitySharingView()
        }
    }
}