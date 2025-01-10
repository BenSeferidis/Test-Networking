//
//  Endpoint.swift
//  Networking
//
//  Created by Ben Seferidis on 10/1/25.
//

import Foundation

/// A typealias combining several common endpoint requirements:
/// - Identifiable: So each endpoint has a unique `id`.
/// - Hashable & Sendable: For concurrency and collection usage.
public typealias Endpointable = Identifiable & Sendable

// MARK: - PROTOCOL: EndpointProtocol

/// A general protocol that users can conform to in order to define API endpoints.
/// It includes standard properties like `baseURL`, `path`, `headers`, and more.
public protocol EndpointProtocol: Endpointable {
    
    /// A unique identifier for the endpoint, useful for diffing or caching.
    var id: UUID { get }

    /// Indicates whether to use HTTP or HTTPS for the endpoint  (e.g. "https://").
    var scheme: SchemeEnum { get }

    /// The server hostname or base URL (e.g. "https://api.myservice.com").
    var baseURL: String { get }
    
    /// The path component of the endpoint (e.g. "/v1/users").
    var path: String? { get }
    
    /// A collection of optional query items appended to the endpoint URL.
    var queryItems: [URLQueryItem]? { get }
    
    /// A dictionary of HTTP headers added to the request.
    var headers: [String: String]? { get }
    
    /// Optional raw `Data` that can be placed in the request body (e.g. JSON or form data).
    var body: Data? { get }
    
    /// The HTTP method for the request (GET, POST, PUT, DELETE).
    var httpMethodEnum: HTTPMethodEnum { get }
    
    /// A dictionary of body parameters to be JSON-encoded and placed in the request body.
    var bodyParameters: [String: Data]? { get set }

    /// Indicates whether caching should be enabled for this endpoint.
    /// Cache policy is `.reloadRevalidatingCacheData`or `.reloadIgnoringLocalCacheData` etc.
    var cachePolicy: URLRequest.CachePolicy { get }
    
    /// New property to indicate which kind of task we're making
    var taskType: NetworkTaskType { get }
    
    /// New property to indicate which kind of ContentType download task we're making
    var contentType: ContentType? { get }
    
    /// Indicates whether caching should be use OAuth flow for this endpoint.
    var authRequired: OAuthRequired? { get }
    
}

public struct OAuthRequired: Sendable {

    /// Indicates whether caching should be use OAuth flow for this endpoint.
    public var isRequired: Bool = false
    
    /// It includes standard properties like `host`, `authBase64String`, `maxRetries`, and more.
    public var configuration: OAuthConfiguration
}

extension EndpointProtocol {

    var url: URL? {
        var components = URLComponents()
        components.scheme = scheme.getValue()
        components.host = baseURL
        components.path = path ?? ""
        components.queryItems = queryItems
        return components.url
    }
    
}

public protocol BaseURLProtocol {
    func getBaseURL() -> String
}

public protocol PathProtocol {
    func getPath() -> String
}

public struct AuthRequired {
    var retries = 3
    
    var isRequired: Bool = false
}

public struct Endpoint: EndpointProtocol {

    // MARK: - Properties
    
    public var id: UUID
    public var scheme: SchemeEnum
    public var baseURL: String
    public var path: String?
    public var queryItems: [URLQueryItem]?
    public var headers: [String: String]?
    public var body: Data?
    public var httpMethodEnum: HTTPMethodEnum
    public var bodyParameters: [String : Data]?
    public var cachePolicy: URLRequest.CachePolicy
    public var taskType: NetworkTaskType
    public var contentType: ContentType?
    public var authRequired: OAuthRequired?
    
    // MARK: - Life cycle
    
    /// Creates an `Endpoint` object, conforming to `EndpointProtocol`.
    ///
    /// - Parameters:
    ///   - id: A unique identifier for the endpoint. Defaults to a new UUID.
    ///   - scheme: The URL scheme (e.g. `.https`). Defaults to `.https`.
    ///   - host: The server hostname (e.g. "https://api").
    ///   - baseURL: The server hostname (e.g. "https://api.example.com/").
    ///   - path: The path component (e.g. "/v1/users").
    ///   - httpMethod: The HTTP method for the request. Defaults to `.GET`.
    ///   - headers: An optional dictionary of HTTP headers.
    ///   - queryItems: Optional `URLQueryItem`s appended to the final URL.
    ///   - body: Optional raw body data (e.g., JSON).
    ///   - bodyParameters: Optional body parameters that will be JSON-encoded.
    ///   - cachePolicy: Determines caching POlicy. Defaults to `.reloadIgnoringLocalCacheData`.
    ///   - authRequired: Determines if OAuth Flow is enabled. Defaults to `false`.
    public init(
        id: UUID = UUID(),
        scheme: SchemeEnum = .https,
        baseURL: BaseURLProtocol,
        path: PathProtocol,
        queryItems: [URLQueryItem]? = nil,
        headers: [String : String]? = nil,
        body: Data? = nil,
        httpMethodEnum: HTTPMethodEnum = .GET,
        bodyParameters: [String : Data]? = nil,
        cachePolicy: URLRequest.CachePolicy = .reloadIgnoringLocalCacheData,
        taskType: NetworkTaskType = .data,
        contentType: ContentType? = .json,
        authRequired: OAuthRequired? = nil
    ) {
        self.id = id
        self.scheme = scheme
        self.baseURL = baseURL.getBaseURL()
        self.path = path.getPath()
        self.queryItems = queryItems
        self.headers = headers
        self.body = body
        self.httpMethodEnum = httpMethodEnum
        self.bodyParameters = bodyParameters
        self.cachePolicy = cachePolicy
        self.taskType = taskType
        self.contentType = contentType
        self.authRequired = authRequired
    }
    
}

// MARK: - ENUM: HTTPMethodEnum

/// Represents common HTTP methods for an endpoint.
public enum HTTPMethodEnum: String, Equatable, Hashable, Sendable {
    /// GET method. Generally used to retrieve data from the server.
    case GET
    /// POST method. Often used to create or send data to the server.
    case POST
    /// PUT method. Often used to update existing data on the server.
    case PUT
    /// DELETE method. Used to delete data on the server.
    case DELETE
}

// MARK: - ENUM: Scheme

/// Represents the URL scheme used in requests, typically `https` or `http`.
public enum SchemeEnum: Equatable, Hashable, Sendable {
    
    case http
    case https
    case custom(value: String)
    
    func getValue() -> String {
        switch self {
        case .http:
            return "http"
        case .https:
            return "https"
        case .custom(let value):
            return value
        }
    }
    
}

public enum NetworkTaskType: Sendable {
    case data
    case download
    case upload(Data)
    case webSocket
}

public enum ContentType: String, Sendable {
    case json = "application/json"
    case xml = "application/xml"
    case formUrlEncoded = "application/x-www-form-urlencoded"
}
