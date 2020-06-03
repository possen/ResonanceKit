//
//  BasicNetworkTests
//
//  Created by Paul Ossenbruggen on 4/5/19.
//

import XCTest

@testable import ResonanceKit
import SwiftCoroutine

struct TestModel: Decodable {
    let value: Int
}

final class BasicNetworkTests: TestBase {

    func testBasics() throws {
        let exp = expectation(description: "testAwait")
        let queue = DispatchQueue.global()
        queue.startCoroutine {
            let request = JSONRequest<TestModel, TestError>(method: .get, path: "/test", session: self.mockSession)
            let result = try request.perform().await()
            XCTAssertEqual(result.value, 10)
            
            let request2 = JSONRequest<TestModel, TestError>(method: .get, path: "/testfail", session: self.mockSession)
            XCTAssertThrowsError(try request2.perform().await())
            
            let request3 = JSONRequest<TestModel, TestError>(method: .get, path: "/", session: self.mockSession)
            XCTAssertNoThrow(try request3.perform(command: "commands/command1").await())
            XCTAssertNoThrow(try request3.perform(command: "commands/command2").await())
            XCTAssertThrowsError(try request3.perform(command: "commands/missing_command").await())
            exp.fulfill()
        }
        wait(for: [exp], timeout: 30)
    }

    func testGetParams() throws {
        let exp = expectation(description: "testAwait")
        let queue = DispatchQueue.global()
        queue.startCoroutine {
            let request = JSONRequest<TestModel, TestError>(
                method: .get,
                path: "/testparams", session: self.mockSession
            )
            let result = try request.perform(parameters: ["param1": "value1", "param2": "value2"] ).await()
            XCTAssertEqual(result.value, 55)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 30)
    }

    func testPostParams() throws {
        let exp = expectation(description: "testAwait")
        let queue = DispatchQueue.global()
        queue.startCoroutine {
            let request = JSONRequest<TestModel, TestError>(method: .post, path: "/testparams", session: self.mockSession)
            let result = try request.perform(parameters: ["param1": "value1", "param2": "value2"] ).await()
            XCTAssertEqual(result.value, 55)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 30)
    }
}
