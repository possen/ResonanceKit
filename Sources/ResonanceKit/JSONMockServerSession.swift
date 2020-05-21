//
//  JSONMockServer.swift
//
//  Created by Paul Ossenbruggen on 4/2/19.
//

import Foundation
import SwiftCoroutine

public class JSONMockServerSession: NetworkSession {
    private let mockServer: JSONMockServer

    public enum MockErrors: Error {
        case loadFailure
        case paramsDidNotParse
        case requestCreationFailure
    }

    public init(mockServer: JSONMockServer) {
        self.mockServer = mockServer
    }

    public func fetchMockRequest(
        request: URLRequest,
        completion: ((data: Data, response: URLResponse)?, Error?) -> Void
    ) {
        if let path = request.url?.path.dropFirst(), let url = request.url, let method = request.httpMethod {
            do {
                let mock = try mockServer.fetchMock(method: method, path: String(path))
                let (request, response, statusCode) = mock
                let params = stringParamsToDict(query: url.query ?? "")
                try checkParams(data: request, params: params)
                guard let httpResponse = HTTPURLResponse(
                    url: url,
                    statusCode: statusCode,
                    httpVersion: "1.2",
                    headerFields: [:]
                ) else {
                    completion(nil, MockErrors.requestCreationFailure)
                    return
                }
                completion((response, httpResponse), nil)
            } catch let error {
                completion(nil, error)
            }
        } else {
            completion(nil, MockErrors.loadFailure)
        }
    }

    public func stringParamsToDict(query: String) -> [String: String] {
        let params = query.components(separatedBy: "&").map {
            $0.components(separatedBy: "=")
            }.reduce(into: [String: String]()) { dict, pair in
                if pair.count == 2 {
                    dict[pair[0]] = pair[1]
                }
        }
        return params
    }

    public func checkParams(data: Data, params: [String: String]) throws {
        guard let decode = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            throw MockErrors.paramsDidNotParse
        }
        logger.debug("matched \(decode)")
    }
}

extension JSONMockServerSession {

    public func loadData(request: URLRequest) throws -> CoFuture<(data: Data, response: URLResponse)> {
        let promise = CoPromise<(data: Data, response: URLResponse)>()
        fetchMockRequest(request: request) { (result, error) in
            if let err = error {
                promise.fail(err)
            } else if let dat = result?.data, let resp = result?.response {
                promise.success((dat, resp))
            } else {
                promise.fail(URLError(.badServerResponse))
            }
        }
        return promise
    }
}
