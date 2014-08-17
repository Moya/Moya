//
//  Moya.swift
//  Moya
//
//  Created by Ash Furrow on 2014-08-16.
//  Copyright (c) 2014 Ash Furrow. All rights reserved.
//

import Foundation

public typealias MoyaCompletion = (AnyObject?) -> ()

public class Moya {
    public enum Method {
        case GET, POST, PUT, DELETE
    }
}

public class MoyaProvider<T: Hashable> {
    public typealias MoyaEndpointsClosure = (T, method: Moya.Method, parameters: [String: AnyObject]) -> (Endpoint<T>)
    public let endpointsClosure: MoyaEndpointsClosure
    let stubResponses: Bool
    
    public init (endpointsClosure: MoyaEndpointsClosure, stubResponses: Bool  = false) {
        self.endpointsClosure = endpointsClosure
        self.stubResponses = stubResponses
    }
    
    public func request(token: T, method: Moya.Method, parameters: [String: AnyObject]?, completion: MoyaCompletion) {
        let endpoint = endpointsClosure(token, method: method, parameters: parameters ?? [String: AnyObject]())
        
        if (stubResponses) {
            let sampleResponse: AnyObject = endpoint.sampleResponse()
            completion(sampleResponse)
        } else {
            let method: Alamofire.Method = methodFromMethod(endpoint.method)
            AF.request(method, endpoint.URL)
                .response({(request: NSURLRequest, reponse: NSHTTPURLResponse?, data: AnyObject?, error: NSError?) -> () in
                    completion(data)
                })
        }
    }
    
    public func request(token: T, parameters: [String: AnyObject]?, completion: MoyaCompletion) {
        request(token, method: Moya.Method.GET, parameters: parameters, completion: completion)
    }

    public func request(token: T, method: Moya.Method, completion: MoyaCompletion) {
        request(token, method: method, parameters: nil, completion: completion)
    }
    
    public func request(token: T, completion: MoyaCompletion) {
        request(token, method: Moya.Method.GET, completion)
    }
}

