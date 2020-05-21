//
//  MockLoader.swift
//  NewNetwork
//
//  Created by Paul Ossenbruggen on 5/28/19.
//

import Foundation

public class JSONMockServer {
    private var mocks: [String: (request: Data, response: Data, statusCode: Int)] = [:]
    private let baseURL: URL
    
    public enum MockErrors: Error {
        case loadFailure
        case mockFolderNotFound
        case mockFileDidNotParse
        case mockResponseMissing
        case mockRequestMissing
        case mockStatusMissing
        case mockMethodMissing
    }

    public func generateKey(method: String, path: String) -> String {
        return "\(method.padding(toLength: 8, withPad:" ", startingAt: 0)) - \(path)"
    }
    
    public init(baseURL: URL) throws {
        self.baseURL = baseURL
        try loadJSONMocks()
    }

    public func fetchMock(method: String, path: String) throws -> (request: Data, response: Data, statusCode: Int) {
        let key = generateKey(method: method, path: path)
        let mock = mocks[key]
        guard let mockValue = mock else {
            throw MockErrors.loadFailure
        }
        return mockValue
    }

    private func loadJSONMocks() throws {
        logger.debug("Loading mocks from \(baseURL)")
        let enumerator = FileManager.default.enumerator(
            at: baseURL,
            includingPropertiesForKeys: nil
        )
        try enumerator?.forEach { fileURL in
            guard let url = fileURL as? URL, url.pathExtension == "json" else {
                return
            }
            let components = url.deletingPathExtension().pathComponents
            let index = components.lastIndex(of: "Mocks")
            if let index = index {
                let remaining = components.suffix(from: index + 1)
                let remainingPath = remaining.reduce("") { $0 + "/" + $1 }
                try loadMocks(name: String(remainingPath.dropFirst()))
            } else {
                throw MockErrors.mockFolderNotFound
            }
        }
    }

    private func loadMocks(name: String) throws {
        let url = baseURL.appendingPathComponent(name).appendingPathExtension("json")
        let data = try Data(contentsOf: url)
        let finalName = name.lowercased()
        // split requests and responses into separate tuples.
        guard let decode = try JSONSerialization.jsonObject(
            with: data
        ) as? [[String: Any]] else {
            throw MockErrors.mockFileDidNotParse
        }
        try decode.forEach {
            try loadMock(decode: $0, path: finalName)
        }
    }
    
    private func loadMock(decode: [String: Any], path: String) throws {
        guard let requestData = decode["request"] else {
            throw MockErrors.mockRequestMissing
        }
        guard let responseData = decode["response"] else {
            throw MockErrors.mockResponseMissing
        }
        guard let statusCodeData = decode["status"] else {
            throw MockErrors.mockStatusMissing
        }
        guard let method = decode["method"] as? String else {
            throw MockErrors.mockMethodMissing
        }
        let key = generateKey(method: method, path: path)
        logger.debug("Loaded Mock: \(key)")
        let request = try JSONSerialization.data(withJSONObject: requestData, options: [])
        let response = try JSONSerialization.data(withJSONObject: responseData, options: [])
        mocks[key] = (request, response, statusCodeData as? Int ?? 200)
    }
}
