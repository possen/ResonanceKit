//
//  JSONRequest,swuft
//  NewNetwork
//
//  Created by Paul Ossenbruggen on 12/14/18.
//

import Foundation
import SwiftCoroutine
import CCoroutine


/// The HTTP Method to use for a request.
public enum HTTPMethod: String {
    case post = "POST"
    case get = "GET"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
    case head = "HEAD"
}

///
/// JSONRequest that will make a JSONRequest and will directly decode the response object in to the parameterized
/// model object.
///
public final class JSONRequest<Model: Decodable, ErrorModel: Decodable & CustomStringConvertible>: NetworkClient {

    /// Errors thrown.
    public enum RESTRequestError: LocalizedError {
        case invalidURL
        case badResponse
        case unableToDecodeErrorResponse
        case badParameter
        case statusCodeResponse(statusCode: Int, message: String)
        
        public var errorDescription: String? {
            switch self {
            case .statusCodeResponse( _, let message):
                return message
            default:
                return self.failureReason
            }
        }
    }
    
    private let url: URL
    private let headers: [String: String]
    private let method: HTTPMethod
    private let urlSession: NetworkSession
    public let decoder = JSONDecoder()
    public let encoder = JSONEncoder()
    
    ///
    /// Make a request without a session object
    ///
    /// Useful if you don't yet have your session object setup with
    /// authorization data etc.
    ///
    /// - parameter method: The default http method to use when making request. Can be overridden in perform.
    /// - parameter url: The full URL, as this does not append a baseURL. Session specifies a baseURL.
    /// - parameter urlSession: Optional, defaults iOS's shared URLSession.
    /// - parameter headers: Headers to apply to the request. Key-Value format.
    ///
    public required init(
        method: HTTPMethod,
        url: URL,
        urlSession: NetworkSession = URLSession.shared,
        headers: [String: String] = [:]
    ) {
        self.url = url
        self.headers = headers
        self.method = method
        self.urlSession = urlSession
    }
    
    ///
    /// Make a request with a session object
    ///
    /// Allows to use a preconfigured Session object so that common information can be passed. Note: recommended that
    /// Session is not a singleton, as Singletons are generally a bad idea. The path is the request after the
    /// baseURL specified in the session object and is appended to that.
    ///
    /// - parameter method: The default http method to use when making request. Can be overridden in perform.
    /// - parameter path: The path relative to the baseURL specified in the Session object.
    /// - parameter urlSession: Optional - if you want to override the shared URLSession.
    /// - parameter headers: Optional - if you want to add headers to the request.
    ///
    /// Note: if path and base URL are invalid a fatal error will be occur,
    ///
    convenience public required init(
        method: HTTPMethod,
        path: String,
        session: JSONSession,
        urlSession: NetworkSession? = nil,
        headers: [String: String] = [:]
     ) {
        guard let url = URL(string: path, relativeTo: session.baseURL) else {
            fatalError("Request URL could not be created from \(path) and baseURL \(session.baseURL)")
        }
        self.init(method: method, url: url, session: session, urlSession: urlSession, headers: headers)
    }
    
    ///
    /// Make a request with a session object
    ///
    /// Allows to use a preconfigured Session object so that common information can be passed. Note: recommended that
    /// Session is not a singleton, as Singletons are generally a bad idea. The path is the request after the
    /// baseURL specified in the session object and is appended to that.
    ///
    /// - parameter method: The default http method to use when making request. Can be overridden in perform.
    /// - parameter url: already defined url, this version does not throw.
    /// - parameter urlSession: Optional if you want to override the shared URLSession.
    /// - parameter headers: Optional if you want to add headers to the request.
    ///
    public required init(
        method: HTTPMethod,
        url: URL,
        session: JSONSession,
        urlSession: NetworkSession? = nil,
        headers: [String: String] = [:]
    ) {
        self.url = url
        self.headers = headers.merging(session.allHeaders) { current, _ in current }
        self.method = method
        self.urlSession = session.urlSession ?? URLSession.shared
        if let keyDecodeStrategy = session.keyDecodingStrategy {
            self.decoder.keyDecodingStrategy = keyDecodeStrategy
        }
        if let dateDecodeStrategy = session.dateDecodingStrategy {
            self.decoder.dateDecodingStrategy = dateDecodeStrategy
        }
        if let dataDecodeStrategy = session.dataDecodingStrategy {
            self.decoder.dataDecodingStrategy = dataDecodeStrategy
        }
        if let keyEncodeStrategy = session.keyEncodingStrategy {
            self.encoder.keyEncodingStrategy = keyEncodeStrategy
        }
        if let dateEncodeStrategy = session.dateEncodingStrategy {
            self.encoder.dateEncodingStrategy = dateEncodeStrategy
        }
        if let dataEncodeStrategy = session.dataEncodingStrategy {
            self.encoder.dataEncodingStrategy = dataEncodeStrategy
        }
    }
    
    ///
    /// Makes the network request.
    ///
    /// The optional command string can be passed for making multiple requests to the same JSONRequest object without
    /// having to specify new path information. This utilizes AwaitKit so that network code can be written sequentially.
    /// rather than many nested closures.
    ///
    /// - parameter method: Optional can override the request's method parameter.
    /// - parameter command: Optional sub command relative to the baseURL and the path specified in the JSONRequest initializer.
    /// - parameter parameters: For .get request append to the url parameters for other added to the body.
    /// - parameter jsonBody: Specifies the jsonBody for the request.
    ///
    /// - throws: Throws if the request fails.
    ///
    @discardableResult public func perform(
        method: HTTPMethod? = nil,
        command: String = "",
        url: URL? = nil,
        parameters: [String: String] = [:],
        body: Data? = nil
    ) throws -> CoFuture<Model> {
        let request: URLRequest
        if let url = url {
            request = URLRequest(url: url)
        } else {
            request = try buildRequest(
                method: method ?? self.method,
                parameters: parameters,
                command: command,
                body: body
            )
        }
        return try perform(request: request)
    }
    
    
    ///
    /// Makes the network request using a URLRequest.
    ///
    /// - parameter request: URLRequest to use.
    ///
    public func perform(request: URLRequest) throws -> CoFuture<Model> {
        logger.debug(request.jsonCurl)
        let future = try urlSession.loadData(request: request)
        let result = try future.await()
        guard let response = result.response as? HTTPURLResponse else {
            throw RESTRequestError.badResponse
        }
        let status = response.statusCode
        let data = result.data.count != 0
            ? result.data
            : "{}".data(using: .utf8)! // empty response
        if 200...299 ~= status {
            logger.debug(String(data: result.data, encoding: .utf8) ?? "Unable to decode response")
            let object = try decoder.decode(Model.self, from: data)
            let promise = CoPromise<Model>()
            promise.success(object)
            return promise
        } else {
            if let errorMessage = try? decoder.decode(ErrorModel.self, from: data) {
                logger.debug(errorMessage.description)
                let error = RESTRequestError.statusCodeResponse(
                    statusCode: status,
                    message: errorMessage.description
                )
                throw error
            }
            throw RESTRequestError.unableToDecodeErrorResponse
        }
    }
    
    // MARK: - Internal methods
    private func buildRequestBody(json: [String: Any]) throws -> Data {
        return try JSONSerialization.data(withJSONObject: json, options: [])
    }

    private func buildRequest(
        method: HTTPMethod,
        parameters: [String: String],
        command: String,
        body: Data?
    ) throws -> URLRequest {
        var request: URLRequest
        
        func add(headers: [String: String]) {
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("*/*", forHTTPHeaderField: "Accept")
            headers.forEach {
                request.addValue($0.1, forHTTPHeaderField: $0.0)
            }
        }
        
        func buildQueryRequest(
            command: String,
            parameters: [String: String],
            method: HTTPMethod
        ) throws -> URLRequest {
            guard var urlComponents = URLComponents(
                url: url,
                resolvingAgainstBaseURL: true
            ) else {
                throw RESTRequestError.invalidURL
            }
            urlComponents.path += command
            if method == .get {
                urlComponents.queryItems = parameters.map { URLQueryItem(name: $0.0, value: $0.1) }
            }
            guard let url = urlComponents.url else {
                throw RESTRequestError.invalidURL
            }
            var request = URLRequest(url: url)
            request.httpMethod = method.rawValue
            return request
        }
        
        request = try buildQueryRequest(command: command, parameters: parameters, method: method)
        // body takes priority over parameters.
        if let body = body {
            request.httpBody = body
        } else if method != .get {
            request.httpBody = try buildRequestBody(json: parameters)
        }
        add(headers: headers)
        return request
    }
}
