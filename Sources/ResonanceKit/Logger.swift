//
//  Logger.swift
//  
//
//  Created by Paul Ossenbruggen on 2/24/20.
//

import Foundation
import SwiftyBeaverKit

public let logger = SwiftyBeaver.self

public struct Logger {
    
    public enum Level: Int {
        case verbose = 0
        case debug = 1
        case info = 2
        case warning = 3
        case error = 4
    }
    
    public init(level: Level) {
        let console = ConsoleDestination()  // log to Xcode Console
        console.minLevel = SwiftyBeaver.Level(rawValue: level.rawValue) ?? .debug
        logger.addDestination(console)
    }
}
