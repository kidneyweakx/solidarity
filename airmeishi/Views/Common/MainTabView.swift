import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var deepLinkManager: DeepLinkManager
    @State private var showingReceivedCard = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        TabView {
            BusinessCardListView()
                .tabItem {
                    Image(systemName: "person.crop.rectangle")
                    Text("My Cards")
                }
            
            ContactListView()
                .tabItem {
                    Image(systemName: "person.2")
                    Text("Contacts")
                }
            
            QRScannerTabView()
                .tabItem {
                    Image(systemName: "qrcode.viewfinder")
                    Text("Scan")
                }
            
            ProximitySharingTabView()
                .tabItem {
                    Image(systemName: "wave.3.right")
                    Text("Share")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
        .sheet(isPresented: $showingReceivedCard) {
            if let card = deepLinkManager.lastReceivedCard {
                ReceivedCardView(card: card)
            }
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .onReceive(deepLinkManager.$pendingAction) { action in
            handleDeepLinkAction(action)
        }
    }
    
    private func handleDeepLinkAction(_ action: DeepLinkAction?) {
        guard let action = action else { return }
        
        switch action {
        case .showReceivedCard:
            showingReceivedCard = true
            
        case .showError(let message):
            errorMessage = message
            showingErrorAlert = true
            
        case .navigateToSharing:
            break
            
        case .navigateToContacts:
            break
        }
        
        deepLinkManager.clearPendingAction()
    }
}


