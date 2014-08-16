//
//  Moya.swift
//  Moya
//
//  Created by Ash Furrow on 2014-08-16.
//  Copyright (c) 2014 Ash Furrow. All rights reserved.
//

import Foundation

public class Moya {
    
}

public class MoyaProvider {
    public let endpoints: Array<Endpoint>
    let stubResponses: Bool
    
    public init (endpoints: Array<Endpoint>, stubResponses: Bool  = false) {
        self.endpoints = endpoints
        self.stubResponses = stubResponses
    }
}