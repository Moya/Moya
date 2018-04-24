//
//  TestNetworkLoggerOutput.swift
//  MoyaTests
//
//  Created by Alan Yeo on 24/4/18.
//

@testable import Moya

class TestNetworkLoggerOutput: DefaultNetworkLoggerOutput {
    var log: String = ""

    override func print(_ separator: String, terminator: String, items: Any...) {
        //mapping the Any... from items to a string that can be compared
        let stringArray: [String] = items.map { $0 as? String }.flatMap { $0 }
        let string: String = stringArray.reduce("") { $0 + $1 + " " }
        log += string
    }
}
