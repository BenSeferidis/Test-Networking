//
//  OAuthConfiguration.swift
//  Networking
//
//  Created by Ben Seferidis on 10/1/25.
//

import Foundation

/// Reconfigure the reAuthNetworkService with new auth parameters.
/// - Parameters:
///   - authHost: The OAuth token endpoint host (e.g., "https://auth.myapp.com").
///   - authBase64String: The "Basic" credentials for the OAuth request.
///   - maxRetries: Number of times to attempt re-auth (default is 3).
///   - retryDelay: Delay in seconds between re-auth retries (default is 4.0).
///

/**
 A configuration object that defines how the reAuthNetworkService should handle OAuth token retrieval and retries.

 This struct allows customizing:
 - The OAuth token endpoint host (`authHost`)
 - Base64-encoded credentials for the Authorization header (`authBase64String`)
 - The maximum number of retry attempts (`maxRetries`)
 - The delay in seconds between each retry attempt (`retryDelay`)
 - An optional custom `EndpointProtocol` implementation (`oauthEndpoint`),
   which can override the default logic for OAuth token requests if needed.
 
 ### Example Usage:
 ```swift
 let config = OAuthConfiguration(
     authHost: "https://auth.example.com",
     authBase64String: "xyz123Base64Creds",
     maxRetries: 5,
     retryDelay: 3.0
 )
 // Pass `config` to a reAuthNetworkService or similar for token retrieval
 */

public struct OAuthConfiguration: Sendable {
    
    // MARK: - Properties
    
    /// The OAuth token endpoint host (e.g. `"https://auth.myapp.com"`).
    public let authHost: String
    
    /// The "Basic" credentials for the OAuth request, base64-encoded.
    public let authBase64String: String
    
    /// Number of times to attempt re-authentication before giving up.
    public let maxRetries: Int
    
    /// Delay in seconds between each re-auth attempt.
    public let retryDelay: TimeInterval
    /// An optional custom endpoint for requesting the OAuth token.
    /// Different projects can provide their own `EndpointProtocol` implementation.
    public let oauthEndpoint: (any EndpointProtocol)?

    // MARK: - LIFE CYCLE
    
    /**
     Creates an `OAuthConfiguration` instance with customizable parameters
     to handle OAuth flows in your networking logic.

     - Parameters:
       - authHost: The OAuth token endpoint host (e.g., `"https://auth.myapp.com"`). Defaults to an empty string.
       - authBase64String: The base64-encoded credentials for the Authorization header. Defaults to an empty string.
       - maxRetries: The number of times to retry re-authentication before failing. Defaults to 3.
       - retryDelay: The delay in seconds between each re-auth attempt. Defaults to 4.0.
       - oauthEndpoint: A user-provided `EndpointProtocol` that can override the default OAuth logic. Defaults to `nil`.
    */
    public init(authHost: String = "",
                authBase64String: String = "",
                maxRetries: Int = 3,
                retryDelay: TimeInterval = 4.0,
                oauthEndpoint: (any EndpointProtocol)? = nil) {
        self.authHost = authHost
        self.authBase64String = authBase64String
        self.maxRetries = maxRetries
        self.retryDelay = retryDelay
        self.oauthEndpoint = oauthEndpoint
    }
}
