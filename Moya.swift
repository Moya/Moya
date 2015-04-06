//
//  Moya.swift
//  Moya
//
//  Created by Ash Furrow on 2014-08-16.
//  Copyright (c) 2014 Ash Furrow. All rights reserved.
//

import Foundation
import Alamofire

/// Block to be executed when a request has completed.
public typealias MoyaCompletion = (data: NSData?, statusCode: Int?, response:NSURLResponse?, error: NSError?) -> ()

/// General-purpose class to store some enums and class funcs.
public class Moya {
    
    /// Represents an HTTP method.
    public enum Method {
        case GET, POST, PUT, DELETE, OPTIONS, HEAD, PATCH, TRACE, CONNECT

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
            case .HEAD:
                return .HEAD
            case .OPTIONS:
                return .OPTIONS
            case PATCH:
                return .PATCH
            case TRACE:
                return .TRACE
            case .CONNECT:
                return .CONNECT
            }
        }
    }

    /// Choice of parameter encoding.
    public enum ParameterEncoding {
        case URL
        case JSON
        case PropertyList(NSPropertyListFormat, NSPropertyListWriteOptions)
        case Custom((URLRequestConvertible, [String: AnyObject]?) -> (NSURLRequest, NSError?))
        
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

    public enum StubbedBehavior {
        case Immediate
        case Delayed(seconds: NSTimeInterval)
    }
    
    /// Default HTTP method is GET.
    public class func DefaultMethod() -> Method {
        return Method.GET
    }
    
    /// Default parameters are empty.
    public class func DefaultParameters() -> [String: AnyObject] {
        return Dictionary<String, AnyObject>()
    }
}

/// Protocol defining the relative path of an enum.
public protocol MoyaPath {
    var path: String { get }
}

/// Protocol to define the base URL and sample data for an enum.
public protocol MoyaTarget : MoyaPath {
    var baseURL: NSURL { get }
    var sampleData: NSData { get }
}

/// Request provider class. Requests should be made through this class only.
public class MoyaProvider<T: MoyaTarget> {
    /// Closure that defines the endpoints for the provider.
    public typealias MoyaEndpointsClosure = (T, method: Moya.Method, parameters: [String: AnyObject]) -> (Endpoint<T>)
    /// Closure that resolves an Endpoint into an NSURLRequest.
    public typealias MoyaEndpointResolution = (endpoint: Endpoint<T>) -> (NSURLRequest)
    public typealias MoyaStubbedBehavior = ((T) -> (Moya.StubbedBehavior))
    
    public let endpointsClosure: MoyaEndpointsClosure
    public let endpointResolver: MoyaEndpointResolution
    public let stubResponses: Bool
    public let stubBehavior: MoyaStubbedBehavior
    
    /// Initializes a provider.
    public init(endpointsClosure: MoyaEndpointsClosure, endpointResolver: MoyaEndpointResolution = MoyaProvider.DefaultEnpointResolution(), stubResponses: Bool  = false, stubBehavior: MoyaStubbedBehavior = MoyaProvider.DefaultStubBehavior) {
        self.endpointsClosure = endpointsClosure
        self.endpointResolver = endpointResolver
        self.stubResponses = stubResponses
        self.stubBehavior = stubBehavior
    }
    
    /// Returns an Endpoint based on the token, method, and parameters by invoking the endpointsClosure.
    public func endpoint(token: T, method: Moya.Method, parameters: [String: AnyObject]) -> Endpoint<T> {
        return endpointsClosure(token, method: method, parameters: parameters)
    }
    
    /// Designated request-making method.
    public func request(token: T, method: Moya.Method, parameters: [String: AnyObject], completion: MoyaCompletion) {
        let endpoint = self.endpoint(token, method: method, parameters: parameters)
        let request = endpointResolver(endpoint: endpoint)

        if stubResponses {
            let behavior = stubBehavior(token)

            let stub: () -> () = {
                switch endpoint.sampleResponse.evaluate() {
                    case .Success(let statusCode, let data):
                        completion(data: data, statusCode: statusCode, response:nil, error: nil)
                    case .Error(let statusCode, let error, let data):
                        completion(data: data, statusCode: statusCode, response:nil, error: error)
                    case .Closure:
                        break  // the `evaluate()` method will never actually return a .Closure
                }
            }

            switch behavior {
            case .Immediate:
                stub()
            case .Delayed(let delay):
                let killTimeOffset = Int64(CDouble(delay) * CDouble(NSEC_PER_SEC))
                let killTime = dispatch_time(DISPATCH_TIME_NOW, killTimeOffset)
                dispatch_after(killTime, dispatch_get_main_queue()) {
                    stub()
                }
            }

        } else {
             Alamofire.Manager.sharedInstance.request(request)
                .response({(request: NSURLRequest, response: NSHTTPURLResponse?, data: AnyObject?, error: NSError?) -> () in
                    // Alamofire always sense the data param as an NSData? type, but we'll
                    // add a check just in case something changes in the future.
                    let statusCode = response?.statusCode
                    if let data = data as? NSData {
                        completion(data: data, statusCode: statusCode, response:response, error: error)
                    } else {
                        completion(data: nil, statusCode: statusCode, response:response, error: error)
                    }
                })
        }
    }
    
    public func request(token: T, parameters: [String: AnyObject], completion: MoyaCompletion) {
        request(token, method: Moya.DefaultMethod(), parameters: parameters, completion: completion)
    }

    public func request(token: T, method: Moya.Method, completion: MoyaCompletion) {
        request(token, method: method, parameters: Moya.DefaultParameters(), completion: completion)
    }
    
    public func request(token: T, completion: MoyaCompletion) {
        request(token, method: Moya.DefaultMethod(), completion: completion)
    }
    
    public class func DefaultEnpointResolution() -> MoyaEndpointResolution {
        return { (endpoint: Endpoint<T>) -> (NSURLRequest) in
            return endpoint.urlRequest
        }
    }

    public class func DefaultStubBehavior(_: T) -> Moya.StubbedBehavior {
        return .Immediate
    }
}

