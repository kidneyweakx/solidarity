import SwiftUI

struct SharingTabView: View {
    @State private var showingScanner = false
    @State private var showingProximitySharing = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                VStack(spacing: 12) {
                    Image(systemName: "square.and.arrow.up.on.square")
                        .font(.system(size: 70))
                        .foregroundColor(.black)
                    Text("Share")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Scan or Share Nearby")
                        .font(.body)
                        .foregroundColor(Color(white: 0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                VStack(spacing: 12) {
                    Button(action: { showingScanner = true }) {
                        HStack {
                            Image(systemName: "qrcode.viewfinder")
                            Text("Scan QR Code")
                        }
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                    }
                    
                    Button(action: { showingProximitySharing = true }) {
                        HStack {
                            Image(systemName: "dot.radiowaves.left.and.right")
                            Text("Proximity Share")
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
        .fullScreenCover(isPresented: $showingScanner) {
            QRScannerView()
        }
        .fullScreenCover(isPresented: $showingProximitySharing) {
            ProximitySharingView()
        }
    }
}


