//
//  Moya.swift
//  Moya
//
//  Created by Ash Furrow on 2014-08-16.
//  Copyright (c) 2014 Ash Furrow. All rights reserved.
//

import Foundation
import Alamofire

public typealias MoyaCompletion = (data: NSData?, error: NSError?) -> ()

public class Moya {
    public enum Method {
        case GET, POST, PUT, DELETE
        
        func method() -> Alamofire.Method {
            switch self {
            case .GET:
                return .GET
            case .POST:
                return .POST
            case .PUT:
                return .PUT
            case .DELETE:
                return .DELETE
            }
        }
    }
    
    public enum ParameterEncoding {
        case URL
        case JSON
        case PropertyList(NSPropertyListFormat, NSPropertyListWriteOptions)
        case Custom((NSURLRequest, [String: AnyObject]?) -> (NSURLRequest, NSError?))
        
        func parameterEncoding() -> Alamofire.ParameterEncoding {
            switch self {
            case .URL:
                return .URL
            case .JSON:
                return .JSON
            case .PropertyList(let format, let options):
                return .PropertyList(format, options)
            case .Custom(let closure):
                return .Custom(closure)
            }
        }
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
    public typealias MoyaEndpointModification = (endpoint: Endpoint<T>) -> (Endpoint<T>)
    public let endpointsClosure: MoyaEndpointsClosure
    let endpointModifier: MoyaEndpointModification
    let stubResponses: Bool
    
    public init(endpointsClosure: MoyaEndpointsClosure, endpointModifier: MoyaEndpointModification = MoyaProvider.DefaultEnpointModification(), stubResponses: Bool  = false) {
        self.endpointsClosure = endpointsClosure
        self.endpointModifier = endpointModifier
        self.stubResponses = stubResponses
    }
    
    public func request(token: T, method: Moya.Method, parameters: [String: AnyObject], completion: MoyaCompletion) {
        let endpoint = self.endpointModifier(endpoint: endpointsClosure(token, method: method, parameters: parameters))
        
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
            let request = endpoint.urlRequest
            Alamofire.Manager.sharedInstance.request(request)
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
    
    public class func DefaultEnpointModification() -> MoyaEndpointModification {
        return { (endpoint: Endpoint<T>) -> (Endpoint<T>) in
            return endpoint
        }
    }
}

