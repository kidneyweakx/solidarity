//
//  airmeishiApp.swift
//  airmeishi
//
//  Created by kidneyweak on 2025/09/09.
//

import SwiftUI
import PassKit

@main
struct airmeishiApp: App {
    // Initialize core managers
    @StateObject private var cardManager = CardManager.shared
    @StateObject private var contactRepository = ContactRepository.shared
    @StateObject private var proximityManager = ProximityManager.shared
    @StateObject private var deepLinkManager = DeepLinkManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(cardManager)
                .environmentObject(contactRepository)
                .environmentObject(proximityManager)
                .environmentObject(deepLinkManager)
                .environmentObject(themeManager)
                .tint(.black)
                .preferredColorScheme(.dark)
                .onAppear {
                    setupApp()
                }
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                    if let url = userActivity.webpageURL {
                        handleIncomingURL(url)
                    }
                }
        }
    }
    
    /// Initialize app components and check permissions
    private func setupApp() {
        // Check if PassKit is available
        if PKPassLibrary.isPassLibraryAvailable() {
            print("PassKit is available")
        } else {
            print("PassKit is not available on this device")
        }
        
        // Check storage availability
        if !StorageManager.shared.isStorageAvailable() {
            print("Warning: Storage is not available")
        }
        
        // Request necessary permissions
        requestPermissions()
        
        // Note: Data is automatically loaded in the managers' init methods
        print("App setup completed")
    }
    
    /// Handle incoming URLs from various sources
    private func handleIncomingURL(_ url: URL) {
        print("App received URL: \(url)")
        
        let handled = deepLinkManager.handleIncomingURL(url)
        
        if !handled {
            print("Failed to handle URL: \(url)")
        }
    }
    
    /// Request necessary permissions for proximity sharing
    private func requestPermissions() {
        // Proximity sharing permissions are handled automatically by MultipeerConnectivity
        // Contact permissions are requested when needed
        
        print("Permissions setup completed")
    }
}
