//
//  Endpoint.swift
//  Moya
//
//  Created by Ash Furrow on 2014-08-16.
//  Copyright (c) 2014 Ash Furrow. All rights reserved.
//

import Foundation
import Alamofire

public enum EndpointSampleResponse {
    case Success(NSData)
    case Error(NSError?)
}

public class Endpoint<T> {
    public let URL: String
    public let method: Moya.Method
    public let sampleResponse: EndpointSampleResponse
    public let parameters: [String: AnyObject]
    
    public init(URL: String, method: Moya.Method, parameters: [String: AnyObject], sampleResponse: EndpointSampleResponse) {
        self.URL = URL
        self.sampleResponse = sampleResponse
        self.method = method
        self.parameters = parameters
    }
    
    public convenience init(URL: String, parameters: [String: AnyObject], sampleResponse: EndpointSampleResponse) {
        self.init(URL: URL, method: Moya.Method.GET, parameters: parameters, sampleResponse: sampleResponse)
    }
    
    public convenience init(URL: String, sampleResponse: EndpointSampleResponse) {
        self.init(URL: URL, parameters: Dictionary<String, AnyObject>(), sampleResponse: sampleResponse)
    }
    
    public func endpointByAddingParameters(parameters: [String: AnyObject]) -> Endpoint<T> {
        var newParameters = self.parameters ?? [String: AnyObject]()
        for (key, value) in parameters {
            newParameters[key] = value
        }
        
        return Endpoint(URL: URL, method: method, parameters: newParameters, sampleResponse: sampleResponse)
    }
}

func methodFromMethod(method: Moya.Method) -> Alamofire.Method {
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
