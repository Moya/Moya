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
    public let parameterEncoding: Moya.ParameterEncoding
    public let httpHeaderFields: [String: AnyObject]
    
    public init(URL: String, sampleResponse: EndpointSampleResponse, method: Moya.Method = Moya.Method.GET, parameters: [String: AnyObject] = [String: AnyObject](), parameterEncoding: Moya.ParameterEncoding = .URL, httpHeaderFields: [String: AnyObject] = [String: AnyObject]()) {
        self.URL = URL
        self.sampleResponse = sampleResponse
        self.method = method
        self.parameters = parameters
        self.parameterEncoding = parameterEncoding
        self.httpHeaderFields = httpHeaderFields
    }
    
    public func endpointByAddingParameters(parameters: [String: AnyObject]) -> Endpoint<T> {
        var newParameters = self.parameters ?? [String: AnyObject]()
        for (key, value) in parameters {
            newParameters[key] = value
        }
        
        return Endpoint(URL: URL, sampleResponse: sampleResponse, method: method, parameters: newParameters, httpHeaderFields: httpHeaderFields)
    }
    
    public func endpointByAddingHTTPHeaderFields(httpHeaderFields: [String: AnyObject]) -> Endpoint<T> {
        var newHTTPHeaderFields = self.httpHeaderFields ?? [String: AnyObject]()
        for (key, value) in parameters {
            newHTTPHeaderFields[key] = value
        }
        
        return Endpoint(URL: URL, sampleResponse: sampleResponse, method: method, parameters: parameters, httpHeaderFields: newHTTPHeaderFields)
    }
}

extension Endpoint {
    public var urlRequest: NSURLRequest {
        var request: NSMutableURLRequest = NSMutableURLRequest(URL: NSURL(string: URL))
        request.HTTPMethod = method.method().toRaw()
        request.allHTTPHeaderFields = httpHeaderFields
        return parameterEncoding.parameterEncoding().encode(request, parameters: parameters).0
    }
}
