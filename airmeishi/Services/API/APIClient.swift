//
//  APIClient.swift
//  airmeishi
//
//  Lightweight HTTP client with CardError mapping
//

import Foundation

/// HTTP method verbs
enum HTTPMethod: String {
    case GET
    case POST
}

/// Simple API client using URLSession
class APIClient {
    static let shared = APIClient()
    
    private let session: URLSession
    private let errorHandler = ErrorHandlingManager.shared
    
    init(session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = APIConfig.requestTimeout
        return URLSession(configuration: configuration)
    }()) {
        self.session = session
    }
    
    // Body-less requests (e.g., GET)
    func request<T: Decodable>(
        path: String,
        method: HTTPMethod = .GET,
        queryItems: [URLQueryItem]? = nil,
        headers: [String: String] = [:],
        includeAuth: Bool = true,
        decodeAs type: T.Type
    ) async -> CardResult<T> {
        do {
            var components = URLComponents(url: APIConfig.baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
            if let queryItems = queryItems, !queryItems.isEmpty {
                components.queryItems = queryItems
            }
            guard let url = components.url else {
                return .failure(.configurationError("Invalid URL components"))
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = method.rawValue
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            if includeAuth, let token = APIAuthManager.shared.getToken() {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            for (key, value) in headers { request.setValue(value, forHTTPHeaderField: key) }
            
            let (data, response) = try await session.data(for: request)
            
            guard let http = response as? HTTPURLResponse else {
                return .failure(.networkError("No HTTP response"))
            }
            
            switch http.statusCode {
            case 200...299:
                do {
                    let decoded = try JSONDecoder().decode(T.self, from: data)
                    return .success(decoded)
                } catch {
                    return .failure(.invalidData("Decoding failed: \(error.localizedDescription)"))
                }
            case 400:
                return .failure(.validationError(parseErrorMessage(data) ?? "Bad Request"))
            case 401:
                return .failure(.unauthorized(parseErrorMessage(data) ?? "Unauthorized"))
            case 404:
                return .failure(.notFound(parseErrorMessage(data) ?? "Not Found"))
            case 429:
                return .failure(.rateLimited(parseErrorMessage(data) ?? "Too Many Requests"))
            default:
                return .failure(.networkError("HTTP \(http.statusCode): \(parseErrorMessage(data) ?? "Unknown error")"))
            }
        } catch {
            let cardError: CardError = .networkError(error.localizedDescription)
            errorHandler.logError(cardError, operation: "API request \(path)")
            return .failure(cardError)
        }
    }
    
    func request<T: Decodable, B: Encodable>(
        path: String,
        method: HTTPMethod = .GET,
        queryItems: [URLQueryItem]? = nil,
        body: B? = nil,
        headers: [String: String] = [:],
        includeAuth: Bool = true,
        decodeAs type: T.Type
    ) async -> CardResult<T> {
        do {
            var components = URLComponents(url: APIConfig.baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
            if let queryItems = queryItems, !queryItems.isEmpty {
                components.queryItems = queryItems
            }
            guard let url = components.url else {
                return .failure(.configurationError("Invalid URL components"))
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = method.rawValue
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // Authorization
            if includeAuth, let token = APIAuthManager.shared.getToken() {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            
            // Extra headers
            for (key, value) in headers { request.setValue(value, forHTTPHeaderField: key) }
            
            // Body
            if let body = body {
                request.httpBody = try JSONEncoder().encode(body)
            }
            
            let (data, response) = try await session.data(for: request)
            
            guard let http = response as? HTTPURLResponse else {
                return .failure(.networkError("No HTTP response"))
            }
            
            switch http.statusCode {
            case 200...299:
                do {
                    let decoded = try JSONDecoder().decode(T.self, from: data)
                    return .success(decoded)
                } catch {
                    return .failure(.invalidData("Decoding failed: \(error.localizedDescription)"))
                }
            case 400:
                return .failure(.validationError(parseErrorMessage(data) ?? "Bad Request"))
            case 401:
                return .failure(.unauthorized(parseErrorMessage(data) ?? "Unauthorized"))
            case 404:
                return .failure(.notFound(parseErrorMessage(data) ?? "Not Found"))
            case 429:
                return .failure(.rateLimited(parseErrorMessage(data) ?? "Too Many Requests"))
            default:
                return .failure(.networkError("HTTP \(http.statusCode): \(parseErrorMessage(data) ?? "Unknown error")"))
            }
        } catch {
            let cardError: CardError = .networkError(error.localizedDescription)
            errorHandler.logError(cardError, operation: "API request \(path)")
            return .failure(cardError)
        }
    }
    
    private func parseErrorMessage(_ data: Data) -> String? {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let message = json["message"] as? String { return message }
        return String(data: data, encoding: .utf8)
    }
}


