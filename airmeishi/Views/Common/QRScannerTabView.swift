import SwiftUI

struct QRScannerTabView: View {
    @State private var showingScanner = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                VStack(spacing: 16) {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("Scan QR Code")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Scan business card QR codes to instantly add contacts")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Button(action: { showingScanner = true }) {
                    HStack {
                        Image(systemName: "camera")
                        Text("Start Scanning")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("QR Scanner")
        }
        .fullScreenCover(isPresented: $showingScanner) {
            QRScannerView()
        }
    }
}