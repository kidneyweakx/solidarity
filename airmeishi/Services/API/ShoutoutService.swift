//
//  ShoutoutService.swift
//  airmeishi
//
//  Shoutout CRUD and realtime websocket
//

import Foundation

class ShoutoutService {
    private let client: APIClient
    private var webSocketTask: URLSessionWebSocketTask?
    private let session: URLSession
    
    init(client: APIClient = .shared) {
        self.client = client
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = APIConfig.requestTimeout
        self.session = URLSession(configuration: configuration)
    }
    
    /// POST /groups/groups/{groupId}/shoutouts
    func create(groupId: String, payload: CreateShoutoutRequest) async -> CardResult<CreateShoutoutResponse> {
        return await client.request(
            path: "groups/groups/\(groupId)/shoutouts",
            method: .POST,
            body: payload,
            decodeAs: CreateShoutoutResponse.self
        )
    }
    
    /// GET /groups/groups/{groupId}/shoutouts?since=...
    func list(groupId: String, since: Double? = nil) async -> CardResult<[Shoutout]> {
        var items: [URLQueryItem] = []
        if let since = since { items.append(URLQueryItem(name: "since", value: String(since))) }
        return await client.request(
            path: "groups/groups/\(groupId)/shoutouts",
            queryItems: items,
            decodeAs: [Shoutout].self
        )
    }
    
    /// Connect WebSocket to /groups/groups/{groupId}/shoutouts/ws
    func connectWebSocket(groupId: String, onMessage: @escaping (Result<Shoutout, CardError>) -> Void) {
        disconnectWebSocket()
        
        guard var components = URLComponents(url: APIConfig.baseURL, resolvingAgainstBaseURL: false) else { return }
        var url = components.url!.appendingPathComponent("groups/groups/\(groupId)/shoutouts/ws")
        
        // Convert http(s) to ws(s)
        if var scheme = components.scheme {
            scheme = scheme == "https" ? "wss" : "ws"
            var wsComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
            wsComponents?.scheme = scheme
            url = wsComponents?.url ?? url
        }
        
        var request = URLRequest(url: url)
        if let token = APIAuthManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        webSocketTask = session.webSocketTask(with: request)
        webSocketTask?.resume()
        receiveMessages(onMessage: onMessage)
        schedulePing()
    }
    
    func disconnectWebSocket() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
    }
    
    private func receiveMessages(onMessage: @escaping (Result<Shoutout, CardError>) -> Void) {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                onMessage(.failure(.networkError(error.localizedDescription)))
            case .success(let message):
                switch message {
                case .data(let data):
                    if let shoutout = try? JSONDecoder().decode(Shoutout.self, from: data) {
                        onMessage(.success(shoutout))
                    } else {
                        onMessage(.failure(.invalidData("Invalid shoutout frame")))
                    }
                case .string(let text):
                    if let data = text.data(using: .utf8), let shoutout = try? JSONDecoder().decode(Shoutout.self, from: data) {
                        onMessage(.success(shoutout))
                    } else {
                        onMessage(.failure(.invalidData("Invalid shoutout frame")))
                    }
                @unknown default:
                    onMessage(.failure(.networkError("Unknown WebSocket message")))
                }
            }
            self.receiveMessages(onMessage: onMessage)
        }
    }
    
    private func schedulePing() {
        guard let task = webSocketTask else { return }
        Task { [weak task] in
            while task?.state == .running {
                try? await Task.sleep(nanoseconds: UInt64(APIConfig.webSocketPingInterval * 1_000_000_000))
                task?.sendPing { _ in }
            }
        }
    }
}


