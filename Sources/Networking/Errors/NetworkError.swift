//
//  NetworkError.swift
//  Networking
//
//  Created by Ben Seferidis on 10/1/25.
//

import Foundation

/// Represents network-related errors that can occur during API calls.
public enum NetworkError: Error, Sendable {
    case badUrl(String? = nil)
    case invalidResponse
    case requestError(String)
    case urlError(URLError)
    case custom(Swift.Error)
    case noInternetConnection
    case timedOut
    case unexpectedStatusCode(Int)
    case dataNotFound
    case decodingFailed(Swift.Error)
    case encodingFailed(Swift.Error)
    case unauthorized
    case forbidden
    case notFound
    case internalServerError
    case reAuthFailed(Swift.Error?)
    case maxRetriesExceeded
    case unknown(Swift.Error?)
   
}

extension NetworkError: LocalizedError {
    
    /// Provides a custom message for each `NetworkError` case.
    public var errorDescription: String? {
        switch self {
        case .badUrl(let comment):
            return NSLocalizedString("The request URL is invalid.", comment: comment ?? "")
        case .requestError(let comment):
            return NSLocalizedString("Invalid response", comment: comment)
        case .urlError(let comment):
            return NSLocalizedString("URL Error.", comment: comment.localizedDescription)
        case .custom(let comment):
            return NSLocalizedString("Custom error.", comment: comment.localizedDescription)
        case .noInternetConnection:
            return NSLocalizedString("No internet connection is available.", comment: "")
        case .timedOut:
            return NSLocalizedString("The request timed out.", comment: "")
        case .unexpectedStatusCode(let statusCode):
            return NSLocalizedString("Unexpected status code: \(statusCode).", comment: "")
        case .dataNotFound:
            return NSLocalizedString("Data not found in the response.", comment: "")
        case .decodingFailed(let error):
            return NSLocalizedString("Failed to decode response: \(error.localizedDescription)", comment: "")
        case .encodingFailed(let error):
            return NSLocalizedString("Failed to encode request: \(error.localizedDescription)", comment: "")
        case .unauthorized:
            return NSLocalizedString("Unauthorized access.", comment: "")
        case .forbidden:
            return NSLocalizedString("Forbidden access.", comment: "")
        case .notFound:
            return NSLocalizedString("Resource not found.", comment: "")
        case .internalServerError:
            return NSLocalizedString("Internal server error.", comment: "")
        case .reAuthFailed(let comment):
            return NSLocalizedString("Re Autheticated error.", comment: comment?.localizedDescription ?? "")
        case .maxRetriesExceeded:
            return NSLocalizedString("Max retries exceeded.", comment: "Reiced max retries")
        case .unknown(let error):
            return error?.localizedDescription ?? NSLocalizedString("An unknown error occurred.", comment: "")
        case .invalidResponse:
            return NSLocalizedString("invalidResponse.", comment: "")
        }
    }
}
