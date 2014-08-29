//
//  Moya.swift
//  Moya
//
//  Created by Ash Furrow on 2014-08-16.
//  Copyright (c) 2014 Ash Furrow. All rights reserved.
//

import Foundation

public typealias MoyaCompletion = (data: NSData?, error: NSError?) -> ()

public class Moya {
    public enum Method {
        case GET, POST, PUT, DELETE
    }
    
    public class func DefaultMethod() -> Method {
        return Method.GET
    }
    
    public class func DefaultParameters() -> [String: AnyObject] {
        return Dictionary<String, AnyObject>()
    }
}

public protocol MoyaPath {
    var path : String { get }
}

public protocol MoyaTarget : MoyaPath {
    var baseURL: NSURL { get }
    var sampleData: NSData { get }
}

public class MoyaProvider<T: MoyaTarget> {
    public typealias MoyaEndpointsClosure = (T, method: Moya.Method, parameters: [String: AnyObject]) -> (Endpoint<T>)
    public let endpointsClosure: MoyaEndpointsClosure
    let stubResponses: Bool
    
    public init(endpointsClosure: MoyaEndpointsClosure, stubResponses: Bool  = false) {
        self.endpointsClosure = endpointsClosure
        self.stubResponses = stubResponses
    }
    
    public func request(token: T, method: Moya.Method, parameters: [String: AnyObject], completion: MoyaCompletion) {
        let endpoint = endpointsClosure(token, method: method, parameters: parameters)
        
        if (stubResponses) {
            // Need to dispatch to the next runloop to give the subject a chance to be subscribed to
            dispatch_async(dispatch_get_main_queue(), {
                switch endpoint.sampleResponse {
                case .Success(let data):
                    completion(data: data, error: nil)
                case .Error(let error):
                    completion(data: nil, error: error)
                }
            })
        } else {
            let method: Alamofire.Method = methodFromMethod(endpoint.method)
            AF.request(method, endpoint.URL)
                .response({(request: NSURLRequest, reponse: NSHTTPURLResponse?, data: AnyObject?, error: NSError?) -> () in
                    // Alamofire always sense the data param as an NSData? type, but we'll
                    // add a check just in case something changes in the future. 
                    if let data = data as? NSData {
                        completion(data: data, error: error)
                    } else {
                        completion(data: nil, error: error)
                    }
                })
        }
    }
    
    public func request(token: T, parameters: [String: AnyObject], completion: MoyaCompletion) {
        request(token, method: Moya.DefaultMethod(), parameters: parameters, completion)
    }

    public func request(token: T, method: Moya.Method, completion: MoyaCompletion) {
        request(token, method: method, parameters: Moya.DefaultParameters(), completion)
    }
    
    public func request(token: T, completion: MoyaCompletion) {
        request(token, method: Moya.DefaultMethod(), completion)
    }
}

