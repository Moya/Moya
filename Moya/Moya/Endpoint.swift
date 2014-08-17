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

public enum Method {
    case GET, POST, PUT, DELETE
}

public class Endpoint<T: Hashable> {
    public let URL: String
    public let method: Method
    let sampleResponse: EndpointSampleResponse
    
    public convenience init(URL: String, sampleResponse: EndpointSampleResponse) {
        self.init(URL: URL, method: .GET, sampleResponse)
    }
    
    public init(URL: String, method: Method, sampleResponse: EndpointSampleResponse) {
        self.URL = URL
        self.sampleResponse = sampleResponse
        self.method = method
    }
}

public func methodFromMethod(method: Method) -> Alamofire.Method {
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
