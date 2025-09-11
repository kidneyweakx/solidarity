import SwiftUI

struct SharingTabView: View {
    @State private var showingProximitySharing = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                VStack(spacing: 12) {
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .font(.system(size: 70))
                        .foregroundColor(.black)
                    Text("Match")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Share nearby or scan a QR inside")
                        .font(.body)
                        .foregroundColor(Color(white: 0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                VStack(spacing: 12) {
                    Button(action: { showingProximitySharing = true }) {
                        HStack {
                            Image(systemName: "dot.radiowaves.left.and.right")
                            Text("Start Matching")
                        }
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Sharing")
            .background(Color.black.ignoresSafeArea())
        }
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .background(Color.black.ignoresSafeArea())
        .fullScreenCover(isPresented: $showingProximitySharing) {
            ProximitySharingView()
        }
    }
}


