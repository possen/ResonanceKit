//
//  URLRequest+Curl.swift
//  Cores
//
//  Created by Paul Ossenbruggen on 8/23/19.
//  Copyright © 2019 Paul Ossenbruggen. All rights reserved.
//
//  Useful utility to format a URLRequest so that it creates a curl command
//
//  On any URLRequest type, in LLDB po print(request.curl) or print(request.jsonCurl)
//

import Foundation

extension URLRequest {
    
    ///
    /// print general curl command.
    ///
    internal var curl: String {
        guard let url = url else { return "" }
        var baseCommand = "curl '\(url.absoluteString)'"
        if httpMethod == "HEAD" {
            baseCommand += " --head"
        }
        var command = [baseCommand]
        if let method = httpMethod, method != "GET" && method != "HEAD" {
            command.append("-X '\(method)'")
        }
        if let headers = allHTTPHeaderFields {
            for (key, value) in headers where key != "Cookie" {
                command.append("-H '\(key): \(value)'")
            }
        }
        if let data = httpBody, let body = String(data: data, encoding: .utf8) {
            command.append("-d '\(body)'")
        }
        return command.joined(separator: " ")
    }
    
    ///
    /// pretty print json result.
    ///
    internal var jsonCurl: String {
        var command = [curl]
        command.append("| python -mjson.tool")
        return command.joined(separator: " ")
    }
}
