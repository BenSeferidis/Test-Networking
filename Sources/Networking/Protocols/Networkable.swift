//
//  Networkable.swift
//  Networking
//
//  Created by Ben Seferidis on 10/1/25.
//

import Foundation
import SwiftUI
import Combine

/// Protocol for API datasource classes that implement network requests.
public protocol Networkable { }

/// Extension of `Networkable` to provide common network request methods.
/// This extension includes async/await, closure, and Combine implementations for making network requests.
extension Networkable {
    
    private var networkService: NetworkServiceProtocol {
        return NetworkService()
    }
    
    /// Makes a network request using async/await.
    ///
    /// - Parameter endPoint: The endpoint configuration used to construct the request.
    /// - Returns: The raw `Data` received from the server.
    /// - Throws: A `NetworkError` if the request fails.
    /// - Example:
    ///   ```swift
    ///   do {
    ///       let data = try await myAPI.getData(endPoint: .fetchData)
    ///       // Process the data
    ///   } catch {
    ///       // Handle error
    ///   }
    ///   ```
    @discardableResult public func getData(endPoint: any EndpointProtocol) async throws -> Data {
        try await networkService.makeRequest(endpoint: endPoint)
    }
    
    /// Makes a network request using async/await.
    ///
    /// - Parameter endPoint: The endpoint configuration used to construct the request.
    /// - Returns: The raw `Data` received from the server.
    /// - Throws: A `NetworkError` if the request fails.
    /// - Example:
    ///   ```swift
    ///   do {
    ///       let data = try await myAPI.getData(endPoint: .fetchData)
    ///       // Process the data
    ///   } catch {
    ///       // Handle error
    ///   }
    ///   ```
    @discardableResult func requestData(endPoint: any EndpointProtocol) async throws -> Data {
        try await networkService.requestData(endpoint: endPoint)
    }
    
    /// Makes a network request using async/await.
    ///
    /// - Parameter endPoint: The endpoint configuration used to construct the request.
    /// - Returns: The raw `URL` received from the server.
    /// - Throws: A `NetworkError` if the request fails.
    /// - Example:
    ///   ```swift
    ///   do {
    ///       let url = try await myAPI.downloadData(endPoint: .endpoint1)
    ///       // Process the url
    ///   } catch {
    ///       // Handle error
    ///   }
    ///   ```
    @discardableResult
    func downloadData(endPoint: any EndpointProtocol) async throws -> URL {
        try await networkService.requestDownload(endpoint: endPoint)
    }
    
    /// Makes a network request using async/await.
    ///
    /// - Parameter endPoint: The endpoint configuration used to construct the request.
    /// - Returns: The raw `Data` received from the server.
    /// - Throws: A `NetworkError` if the request fails.
    /// - Example:
    ///   ```swift
    ///   do {
    ///       let uploadData = Data()
    ///       let data = try await myAPI.requestUpload(endpoint: .endpoint1, data: uploadData)
    ///       // Process the data
    ///   } catch {
    ///       // Handle error
    ///   }
    ///   ```
    @discardableResult
    func uploadData(endPoint: any EndpointProtocol, data: Data) async throws -> Data {
        try await networkService.requestUpload(endpoint: endPoint, data: data)
    }
    
    /// Makes a network request using async/await.
    ///
    /// - Parameter endPoint: The endpoint configuration used to construct the request.
    /// - Returns: The raw `URLSessionWebSocketTask` received from the server.
    /// - Throws: A `NetworkError` if the request fails.
    /// - Example:
    ///   ```swift
    ///   do {
    ///       let data = try await myAPI.openWebSocket(endPoint: .endpoint1)
    ///       // Process the data
    ///   } catch {
    ///       // Handle error
    ///   }
    ///   ```
    func openWebSocket(endPoint: any EndpointProtocol) async throws -> URLSessionWebSocketTask {
        try await networkService.requestWebSocket(endpoint: endPoint)
    }

}
