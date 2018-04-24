//
//  NetworkLoggerOutput.swift
//  Moya
//
//  Created by Alan Yeo on 24/4/18.
//

import Foundation

public protocol NetworkLoggerOutput {
    func print(_ separator: String, terminator: String, items: Any...)
    func format(_ loggerId: String, date: String, identifier: String, message: String) -> String
}

class DefaultNetworkLoggerOutput: NetworkLoggerOutput {
    func print(_ separator: String, terminator: String, items: Any...) {
        for item in items {
            Swift.print(item, separator: separator, terminator: terminator)
        }
    }

    func format(_ loggerId: String, date: String, identifier: String, message: String) -> String {
        return "\(loggerId): [\(date)] \(identifier): \(message)"
    }
}
