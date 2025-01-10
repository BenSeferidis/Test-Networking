//
//  AuthenticateService.swift
//  Networking
//
//  Created by Ben Seferidis on 10/1/25.
//

import Foundation

/// The `AuthenticateService` is now fully responsible for handling:
/// - How many times to retry
/// - The delay between retries
/// - Calling the `AuthenticateService` to fetch the token
public actor AuthenticateService {
    
    // MARK: - Properties
    
    /// A reference to a `NetworkServiceProtocol` service to make the token request
    private let networkService: NetworkServiceProtocol
    
    private let configuration: OAuthConfiguration
    private(set) var token: String?
    
    // MARK: - Life Cycle
    
    public init(networkService: NetworkServiceProtocol, configuration: OAuthConfiguration) {
        self.networkService = networkService
        self.configuration = configuration
    }
    
    // MARK: - Methods
    
    /// Attempts to re-authenticate by fetching a new token.
    /// Retries up to `maxRetries` times, waiting `retryDelay` seconds between attempts.
    /// On success, updates `self.token`.
    /// On failure, throws a `ANNetworkError`.
    func reAuthenticate() async throws {
        for attempt in 1...configuration.maxRetries {
            guard let oauthEndpoint = configuration.oauthEndpoint else {
                throw NetworkError.badUrl(nil)
            }
            do {
                let data = try await networkService.request(endpoint: oauthEndpoint)
                let response: OAuthResponse = try JSONDecoder().decode(OAuthResponse.self, from: data)
                guard let newToken = response.token else {
                    throw NetworkError.reAuthFailed(nil)
                }
                self.token = newToken
                return
            } catch {
                /// If this was the last attempt, rethrow
                if attempt == configuration.maxRetries {
                    throw NetworkError.maxRetriesExceeded
                }
                /// Otherwise wait before trying again
                try await Task.sleep(nanoseconds: UInt64(configuration.retryDelay * 1_000_000_000))
            }
        }
    }
    
}

// MARK: - OAuthResponse Model

/// Represents the response from the OAuth endpoint.
/// Adjust this struct to match the actual response fields from your OAuth server.
struct OAuthResponse: Codable, Sendable {
    let token: String?
    let expiresIn: Int?

    enum CodingKeys: String, CodingKey {
        case token = "access_token"
        case expiresIn = "expires_in"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        token = try container.decodeIfPresent(String.self, forKey: .token)
        
        /// Attempt to decode `expires_in` as Int directly
        if let intVal = try? container.decode(Int.self, forKey: .expiresIn) {
            expiresIn = intVal
        } else if let stringVal = try? container.decode(String.self, forKey: .expiresIn),
                  let intVal = Int(stringVal) {
            /// If it's a string convertible to int
            expiresIn = intVal
        } else {
            /// Neither int nor string convertible to int; handle as needed
            expiresIn = nil
        }
    }
}
