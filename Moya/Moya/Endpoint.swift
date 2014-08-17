//
//  Endpoint.swift
//  Moya
//
//  Created by Ash Furrow on 2014-08-16.
//  Copyright (c) 2014 Ash Furrow. All rights reserved.
//

import Foundation

public typealias EndpointConfiguration = () -> ()
public typealias EndpointSampleResponse = () -> (AnyObject)

public class Endpoint<T: Hashable> {
    public let URL: String
    public let method: Moya.Method
    let sampleResponse: EndpointSampleResponse
    
    public init(URL: String, method: Moya.Method, sampleResponse: EndpointSampleResponse) {
        self.URL = URL
        self.sampleResponse = sampleResponse
        self.method = method
    }
    
    public convenience init(URL: String, sampleResponse: EndpointSampleResponse) {
        self.init(URL: URL, method: Moya.Method.GET, sampleResponse: sampleResponse)
    }
}

public func methodFromMethod(method: Moya.Method) -> Alamofire.Method {
    switch method {
    case .GET:
        return Alamofire.Method.GET
    case .POST:
        return Alamofire.Method.POST
    case .PUT:
        return Alamofire.Method.PUT
    case .DELETE:
        return Alamofire.Method.DELETE
    }
}
