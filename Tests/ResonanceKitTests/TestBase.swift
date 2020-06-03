//
//  RiderTestBase.swift
//  ResonanceKit
//
//  Created by Paul Ossenbruggen on 5/19/20.
//  Copyright © 2020 Paul Ossenbruggen. All rights reserved.
//

import Foundation
import XCTest
import ResonanceKit

class TestBase: XCTestCase {
    
    enum TestError: String, Error, Decodable, CustomStringConvertible {
        var description: String {
            return self.rawValue
        }
        
        case general
    }
    var jsonMockServer: JSONMockServer!
    var mockSession: JSONSession!

    private var baseURL: URL {
        let testBundle = Bundle(for: type(of: self))
        return testBundle.bundleURL.appendingPathComponent("Mocks")
    }

    override func setUp() {
        do {
            jsonMockServer = try JSONMockServer(baseURL: baseURL)
            let jsonMockServerSession = JSONMockServerSession(mockServer: jsonMockServer)
            let mockSession = JSONSession(baseURL: URL(string: "https://mocktest.com")!)
            mockSession.urlSession = jsonMockServerSession
            self.mockSession = mockSession
        } catch let error {
            fatalError(error.localizedDescription)
        }
    }
}
