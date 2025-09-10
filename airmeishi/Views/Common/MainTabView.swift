import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var deepLinkManager: DeepLinkManager
    @State private var showingReceivedCard = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                BusinessCardListView()
                    .tag(0)
                
                SharingTabView()
                    .tag(1)
                
                ShoutoutView()
                    .tag(2)
                
                IDView()
                    .tag(3)
            }
            .tabViewStyle(DefaultTabViewStyle())
            .toolbarBackground(.hidden, for: .tabBar)
            .toolbar(.hidden, for: .tabBar)

            CustomFloatingTabBar(selectedTab: $selectedTab)
        }
        .background(Color.black.ignoresSafeArea())
        .tint(.white)
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


