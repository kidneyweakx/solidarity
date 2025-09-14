//
//  APIConfig.swift
//  airmeishi
//
//  Central API configuration for base URLs and timeouts
//

import Foundation

/// Centralized API configuration
struct APIConfig {
    /// Default API base URL
    static var baseURL: URL {
        // Keep in sync with server deployment
        return URL(string: "https://luftdeck.sololin.xyz/")!
    }
    
    /// Request timeout interval
    static let requestTimeout: TimeInterval = 15
    
    /// WebSocket ping interval (seconds)
    static let webSocketPingInterval: TimeInterval = 20
}


