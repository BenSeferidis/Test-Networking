// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import Combine

/// Protocol defining the requirements for a network service to make requests.
public protocol NetworkServiceProtocol: Actor, Sendable {
    
    /// Makes a network request using async/await.
    ///
    /// - Parameter endpoint: The endpoint configuration used to construct the request.
    /// - Returns: The raw `Data` received from the server.
    /// - Throws: A `NetworkError` if the request fails.
    func makeRequest(endpoint: any EndpointProtocol) async throws -> Data
    
    /// Makes a network request using async/await.
    ///
    /// - Parameter endpoint: The endpoint configuration used to construct the request.
    /// - Returns: The raw `Data` received from the server.
    /// - Throws: A `NetworkError` if the request fails.
    func requestData(endpoint: any EndpointProtocol) async throws -> Data
    
    /// Makes a network request using async/await.
    ///
    /// - Parameter endpoint: The endpoint configuration used to construct the request.
    /// - Returns: The raw `URL` received from the server.
    /// - Throws: A `NetworkError` if the request fails.
    func requestDownload(endpoint: any EndpointProtocol) async throws -> URL
    
    /// Makes a network request using async/await.
    ///
    /// - Parameter endpoint: The endpoint configuration used to construct the request.
    /// - Returns: The raw `Data` upload to the server.
    /// - Throws: A `NetworkError` if the request fails.
    func requestUpload(endpoint: any EndpointProtocol, data: Data) async throws -> Data
    
    /// Makes a network request using async/await.
    ///
    /// - Parameter endpoint: The endpoint configuration used to construct the request.
    /// - Returns: The raw `URLSessionWebSocketTask`opens socket with the server.
    /// - Throws: A `NetworkError` if the request fails.
    func requestWebSocket(endpoint: any EndpointProtocol) async throws -> URLSessionWebSocketTask
    
    var session: URLSession { get }
    
    var authRequired: AuthRequired? { get }
}

/// `NetworkService` is a concrete implementation of the `NetworkServiceProtocol` protocol.
/// It provides methods for making network requests using Alamofire, supporting async/await, closure, and Combine paradigms.
actor NetworkService: NetworkServiceProtocol {
    
    // MARK: - PROPERTIES 🌐 PUBLIC
    
    var session: URLSession
    var authRequired: AuthRequired?
    
    // MARK: - PROPERTIES 🔰 PRIVATE
    
    // MARK: - LIFE CYCLE
    
    init(session: URLSession = .shared, authRequired: AuthRequired? = nil) {
        NetworkLogger.isLoggingEnabled = Preferences.printLogs
        self.session = session
        self.authRequired = authRequired
    }

}

// MARK: - EXTENSION 🌐 PUBLIC

extension NetworkServiceProtocol {
    
    // MARK: - METHODS 🌐 PUBLIC

    // Data Task

    func requestData(endpoint: any EndpointProtocol) async throws -> Data {
        /// If `403` is encountered and `useReAuth` is true,
        /// it will try to re-authenticate and retry up to `maxReAuthAttempts` times.
        do {
            return try await performRequest(endpoint: endpoint)
        } catch let netError as NetworkError {
            guard let authRequired else { throw netError }
            /// Check for 403 and if we can attempt re-auth
            if case .forbidden = netError, let authRequired = endpoint.authRequired {
                /// Delegate all retry logic to AuthenticateService
                try await AuthenticateService(networkService: self, configuration: authRequired.configuration).reAuthenticate()
                /// Now that we (hopefully) have a new token, retry the request
                return try await performRequest(endpoint: endpoint)
            } else {
                /// Rethrow if we are not using re-auth or no attempts left
                throw NetworkError.maxRetriesExceeded
            }
        }
    }
    
    // Download Task
    
    func requestDownload(endpoint: any EndpointProtocol) async throws -> URL {
        let request = try await requestBuilder(endpoint: endpoint)
        
        /// Download task with async/await
        let (fileURL, response) = try await session.download(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = NetworkError.requestError("Invalid response")
            NetworkLogger.log(error: error)
            throw error
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let error = NetworkError.unexpectedStatusCode(httpResponse.statusCode)
            NetworkLogger.log(error: error)
            throw error
        }
        
        return fileURL
    }
    
    // Upload Task
    
    func requestUpload(endpoint: any EndpointProtocol, data: Data) async throws -> Data {
        let request = try await requestBuilder(endpoint: endpoint)
                
        /// `upload(for:from:)` is the async/await variant of an upload task
        let (data, response) = try await session.upload(for: request, from: data)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = NetworkError.requestError("Invalid response")
            NetworkLogger.log(error: error)
            throw error
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let error = NetworkError.unexpectedStatusCode(httpResponse.statusCode)
            NetworkLogger.log(error: error)
            throw error
        }
        
        return data
    }
    
    // WebSocket Task
    
    func requestWebSocket(endpoint: any EndpointProtocol) async throws -> URLSessionWebSocketTask {
        guard let url = endpoint.url else {
            throw NetworkError.badUrl(nil)
        }
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.httpMethodEnum.rawValue
        
        /// Optionally configure headers, etc.
        request.allHTTPHeaderFields = endpoint.headers
        
        /// Create a web socket task
        let webSocketTask = session.webSocketTask(with: request)
        return webSocketTask
    }
    
    // ASYNC AWAIT REQUESTS
    
    func makeRequest(endpoint: any EndpointProtocol) async throws -> Data {
        /// If `403` is encountered and `useReAuth` is true,
        /// it will try to re-authenticate and retry up to `maxReAuthAttempts` times.
        do {
            return try await performAsyncRequest(endpoint: endpoint)
        } catch let netError as NetworkError {
            guard let authRequired else { throw netError }
            /// Check for 403 and if we can attempt re-auth
            if case .forbidden = netError, let authRequired = endpoint.authRequired {
                /// Delegate all retry logic to AuthenticateService
                try await AuthenticateService(networkService: self, configuration: authRequired.configuration).reAuthenticate()
                /// Now that we (hopefully) have a new token, retry the request
                return try await performRequest(endpoint: endpoint)
            } else {
                /// Rethrow if we are not using re-auth or no attempts left
                throw NetworkError.maxRetriesExceeded
            }
        }
    }

}

// MARK: - EXTENSION 🔰 PRIVATE

extension NetworkServiceProtocol {
    
    // MARK: - METHODS 🔰 PRIVATE
    
    /// Build the URL Request using the endpoint
    private func requestBuilder(endpoint: any EndpointProtocol) async throws -> URLRequest {
        
        guard let url = endpoint.url else {
            let error = NetworkError.badUrl(endpoint.baseURL+(endpoint.path ?? ""))
            NetworkLogger.log(error: error)
            throw error
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.cachePolicy = endpoint.cachePolicy
        urlRequest.httpMethod = endpoint.httpMethodEnum.rawValue
        
        /// Add headers
        endpoint.headers?.forEach { key, value in
            urlRequest.setValue(String(describing: value), forHTTPHeaderField: key)
        }
        
        /// If the endpoint has a `contentType`, set the header
        if let contentType = endpoint.contentType {
            urlRequest.setValue(contentType.rawValue, forHTTPHeaderField: "Content-Type")
        }
        
        /// Body data
        if let body = endpoint.body {
            urlRequest.httpBody = body
        }
        
        /// Encode body parameters into JSON and set as httpBody
        if let bodyParameters = endpoint.bodyParameters {
            let jsonData = try JSONSerialization.data(withJSONObject: bodyParameters, options: [])
            urlRequest.httpBody = jsonData
        }
        
        return urlRequest
    }
    
    private func performRequest(endpoint: any EndpointProtocol) async throws -> Data {
        let urlRequest = try await requestBuilder(endpoint: endpoint)

        do {
            NetworkLogger.log(request: urlRequest)
            
            let startTime = Date() /// Record the start time
    
            let (data, response) = try await session.data(for: urlRequest)
            
            let endTime = Date() /// Record the end time
            let duration = endTime.timeIntervalSince(startTime) /// Calculate the duration
    
            guard let httpResponse = response as? HTTPURLResponse else {
                let error = NetworkError.requestError("Invalid response")
                NetworkLogger.log(error: error)
                throw error
            }
            
            NetworkLogger.log(data: data, response: response, error: nil, request: urlRequest, duration: duration)
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let error = NetworkError.unexpectedStatusCode(httpResponse.statusCode)
                NetworkLogger.log(error: error)
                throw error
            }
            
            return data
            
        } catch let error as URLError {
            NetworkLogger.log(error: error)
            throw NetworkError.urlError(error)
        } catch let error as NSError {
            NetworkLogger.log(error: error)
            throw NetworkError.custom(error)
        } catch let error as NetworkError {
            NetworkLogger.log(error: error)
            throw NetworkError.custom(error)
        } catch {
            NetworkLogger.log(error: error)
            throw NetworkError.unknown(error)
        }
    }
    
    /// URLSession async await
    private func performAsyncRequest<T: Codable & Sendable>(endpoint: any EndpointProtocol) async throws -> T {
        guard let urlRequest = try? await self.requestBuilder(endpoint: endpoint) else {
            throw NetworkError.badUrl(nil)
        }

        return try await withCheckedThrowingContinuation { continuation in
            guard let url = urlRequest.url else {
                continuation.resume(throwing: NetworkError.badUrl(nil))
                return
            }
            let task = session.dataTask(with: urlRequest) { data, response, error in
                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.resume(throwing:NetworkError.requestError("Invalid response"))
                        return
                    }
                    
                    guard error == nil else {
                        continuation.resume(throwing: NetworkError.requestError("Invalid error"))
                        return
                    }
                    
                    guard 200...299 ~= httpResponse.statusCode else {
                        continuation.resume(throwing: NetworkError.unexpectedStatusCode(httpResponse.statusCode))
                        return
                    }
                    
                    guard let data = data else {
                        continuation.resume(throwing: NetworkError.dataNotFound)
                        return
                    }
                    
                    do {
                        let decodedResponse: T = try JSONDecoder().decode(T.self, from: data)
                        continuation.resume(returning: decodedResponse)
                    } catch {
                        continuation.resume(throwing: NetworkError.decodingFailed(error))
                    }

                }
            task.resume()
        }
    }

}

extension NetworkService {
    
    /// Maps an `URLResponse` from URLSession to a `NetworkError`.
    ///
    /// - Parameter error: The `URLResponse` received from URLResponse.
    /// - Returns: A `NetworkError` that represents the error more specifically.
    private func handleStatusCode(response: URLResponse?) throws -> NetworkError {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 401:
            return NetworkError.unauthorized
        case 403:
            return NetworkError.forbidden
        case 404:
            throw NetworkError.notFound
        case 500:
            throw NetworkError.internalServerError
        default:
            throw NetworkError.unknown(nil)
        }
    }
    
    private func extractETag(from response: URLResponse?) -> String? {
        guard let httpResponse = response as? HTTPURLResponse else {
            return nil
        }
        return httpResponse.allHeaderFields["ETag"] as? String
    }

}
