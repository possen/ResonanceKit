//
//  Session.swift
//  ResonanceKit
//
//  Created by Paul Ossenbruggen on 5/20/20.
//  Copyright © 2020 Paul Ossenbruggen. All rights reserved.
//

import Foundation
import SwiftCoroutine

///
/// This configures defaults that are reused. You can make requests without a session but
/// you will need to pass the information. The session can be a Mock session which implements the NetworkSession
/// protocol or it can be the URLSession extension below. See JSONMockServer.swift for a mock server. Setting
/// the various properties gives you control over all requests made with this session.
///
public class JSONSession {
    let baseURL: URL
    public var headers: [String: String] = [:]
    public var urlSession: NetworkSession? = nil
    public var keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy?
    public var dateDecodingStrategy: JSONDecoder.DateDecodingStrategy?
    public var dataDecodingStrategy: JSONDecoder.DataDecodingStrategy?
    public var keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy?
    public var dateEncodingStrategy: JSONEncoder.DateEncodingStrategy?
    public var dataEncodingStrategy: JSONEncoder.DataEncodingStrategy?
    public var authToken = ""
    
    var allHeaders: [String: String] {
        guard authToken != "" else {
            return [:]
        }
        return ["Authorization": authToken].merging(headers) { current, _ in current }
    }
    
    public init(session: JSONSession) {
        self.baseURL = session.baseURL
        self.headers = session.headers
        self.urlSession = session.urlSession
        self.keyDecodingStrategy = session.keyDecodingStrategy
        self.dataDecodingStrategy = session.dataDecodingStrategy
        self.dateDecodingStrategy = session.dateDecodingStrategy
        self.keyEncodingStrategy = session.keyEncodingStrategy
        self.dateDecodingStrategy = session.dateDecodingStrategy
        self.dataEncodingStrategy = session.dataEncodingStrategy
        self.authToken = session.authToken
    }
    
    ///
    /// Initializes a Session object.
    ///
    /// - parameter baseURL: The baseURL all reqeusts will be relative paths from this base URL.
    ///
    public init(baseURL: URL) {
        self.baseURL = baseURL
    }
}

///
/// Defines an interface for invoking network requests.
///
internal protocol NetworkClient {
    associatedtype Model: Decodable

    /// The perform command invokes the request on the Server
    ///
    /// - parameter method: Optional can override the request's method parameter.
    /// - parameter command: optional parameter to allow commands from same root specified in the JSONRequest
    /// - parameter parameters: optional parameters to add to query portion or body of the request depending on request type.
    /// - parameter jsonBody: JSON to send in the body of the request
    ///
    /// - returns: A promise to return the value of the type specified.
    ///
    func perform(
        method: HTTPMethod?,
        command: String,
        parameters: [String: String],
        body: Data?
    ) throws -> CoFuture<Model>
}

/// Common interface for session object.
public protocol NetworkSession {
  
    ///
    /// Implements the PromiseKit.Foundation network interface.
    ///
    func loadData(request: URLRequest) throws -> CoFuture<(data: Data, response: URLResponse)>
}

///
/// extension to add loadData to regular URLSession
///
extension URLSession: NetworkSession {

    public func loadData(request: URLRequest) throws -> CoFuture<(data: Data, response: URLResponse)> {
        let promise = CoPromise<(data: Data, response: URLResponse)>()
        let task = dataTask(with: request) { data, response, error in
            if let err = error {
                promise.fail(err)
            } else if let dat = data, let resp = response {
                promise.success((dat, resp))
            } else {
                promise.fail(URLError(.badServerResponse))
            }
        }
        task.resume()
        return promise
    }
}

