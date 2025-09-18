//
//  airmeishiApp.swift
//  airmeishi
//
//  Created by kidneyweak on 2025/09/09.
//

import SwiftUI
import PassKit
import Foundation

#if canImport(CoinbaseWalletSDK)
import CoinbaseWalletSDK
#endif

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

        // Configure Coinbase Wallet SDK
        #if canImport(CoinbaseWalletSDK)
        print("🔗 [App] Configuring Coinbase Wallet SDK...")
        let callbackURL = URL(string: "airmeishi://")!
        print("🔗 [App] Callback URL: \(callbackURL)")
        print("🔗 [App] Callback scheme: \(callbackURL.scheme ?? "nil")")
        print("🔗 [App] Callback host: \(callbackURL.host ?? "nil")")
        print("🔗 [App] Callback path: \(callbackURL.path)")
        
        CoinbaseWalletSDK.configure(callback: callbackURL)
        print("🔗 [App] Coinbase Wallet SDK configured successfully")
        #else
        print("🔗 [App] Coinbase Wallet SDK not available - skipping configuration")
        #endif
    }
    
    /// Handle incoming URLs from various sources
    private func handleIncomingURL(_ url: URL) {
        print("🔗 [App] Received URL: \(url)")
        print("🔗 [App] URL scheme: \(url.scheme ?? "nil")")
        print("🔗 [App] URL host: \(url.host ?? "nil")")
        print("🔗 [App] URL path: \(url.path)")
        print("🔗 [App] URL query: \(url.query ?? "nil")")
        print("🔗 [App] URL absoluteString: \(url.absoluteString)")
        
        #if canImport(CoinbaseWalletSDK)
        print("🔗 [App] Attempting Coinbase Wallet SDK handling...")
        
        // Decode the URL parameter to see what's inside
        if let query = url.query, query.contains("p=") {
            print("🔗 [App] Decoding URL parameter...")
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            if let p = components?.queryItems?.first(where: { $0.name == "p" })?.value {
                if let data = Data(base64Encoded: p) {
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("🔗 [App] Decoded content: \(json)")
                    } else {
                        print("🔗 [App] Failed to decode JSON from base64")
                    }
                } else {
                    print("🔗 [App] Failed to decode base64")
                }
            }
        }
        
        do {
            let handledByWallet = try CoinbaseWalletSDK.shared.handleResponse(url)
            print("🔗 [App] Coinbase Wallet SDK result: \(handledByWallet)")
        } catch {
            print("🔗 [App] Coinbase Wallet SDK error: \(error)")
        }
        
        // Try alternative handling methods
        let handledByWallet = (try? CoinbaseWalletSDK.shared.handleResponse(url)) == true
        
        // If the standard method fails, try handling it as a deep link
        if !handledByWallet {
            print("🔗 [App] Standard handling failed, trying alternative...")
            // The URL might need to be handled differently
            // Let's see if we can extract the response data manually
        }
        #else
        print("🔗 [App] Coinbase Wallet SDK not available")
        let handledByWallet = false
        #endif
        
        print("🔗 [App] Attempting DeepLinkManager handling...")
        let handledByDeepLink = deepLinkManager.handleIncomingURL(url)
        print("🔗 [App] DeepLinkManager result: \(handledByDeepLink)")
        
        let handled = handledByDeepLink || handledByWallet
        print("🔗 [App] Overall handled: \(handled)")
        
        if !handled {
            print("❌ [App] Failed to handle URL: \(url)")
        } else {
            print("✅ [App] Successfully handled URL: \(url)")
        }
    }
    
    /// Request necessary permissions for proximity sharing
    private func requestPermissions() {
        // Proximity sharing permissions are handled automatically by MultipeerConnectivity
        // Contact permissions are requested when needed
        
        print("Permissions setup completed")
    }
}
