//
//  Moya.swift
//  Moya
//
//  Created by Ash Furrow on 2014-08-16.
//  Copyright (c) 2014 Ash Furrow. All rights reserved.
//

import Foundation

public typealias MoyaCompletion = (AnyObject?) -> ()

private var MoyaProviderInflightRequestKey: Void?

@objc public class Moya {
    public enum Method {
        case GET, POST, PUT, DELETE
    }
}

@objc public class MoyaProvider<T: Hashable> {
    public typealias MoyaEndpointsClosure = (T, method: Moya.Method, parameters: [String: AnyObject]) -> (Endpoint<T>)
    public let endpointsClosure: MoyaEndpointsClosure
    let stubResponses: Bool
    
    public init (endpointsClosure: MoyaEndpointsClosure, stubResponses: Bool  = false) {
        self.endpointsClosure = endpointsClosure
        self.stubResponses = stubResponses
    }
    
    public func request(token: T, method: Moya.Method, parameters: [String: AnyObject]?) -> RACSignal {
        let endpoint = endpointsClosure(token, method: method, parameters: parameters ?? [String: AnyObject]())
        
        let subject = RACSubject()
        
        if (stubResponses) {
            // Need to dispatch to the next runloop to give the subject a chance to be subscribed to
            dispatch_async(dispatch_get_main_queue(), {
                let sampleResponse: AnyObject = endpoint.sampleResponse()
                subject.sendNext(sampleResponse)
                subject.sendCompleted()
            })
        } else {
            let method: Alamofire.Method = methodFromMethod(endpoint.method)
            AF.request(method, endpoint.URL)
                .response({(request: NSURLRequest, reponse: NSHTTPURLResponse?, data: AnyObject?, error: NSError?) -> () in
                    if let error = error {
                        subject.sendError(error)
                    } else {
                        if let data: AnyObject = data {
                            subject.sendNext(data)
                        }
                        subject.sendCompleted()
                    }
                })
        }
        
        return subject
    }
    
    public func request(token: T, parameters: [String: AnyObject]?) -> RACSignal {
        return request(token, method: Moya.Method.GET, parameters: parameters)
    }

    public func request(token: T, method: Moya.Method) -> RACSignal {
        return request(token, method: method, parameters: nil)
    }
    
    public func request(token: T) -> RACSignal {
        return request(token, method: Moya.Method.GET)
    }
    
    var inflightRequests: [Endpoint<T>: RACSignal] {
        if let requests = objc_getAssociatedObject(self, &MoyaProviderInflightRequestKey) as? [Endpoint<T>: RACSignal] {
            return requests
        } else {
            var requests = [Endpoint<T>: RACSignal]()
            objc_setAssociatedObject(self, &MoyaProviderInflightRequestKey, requests, UInt(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
            return requests
        }
    }
}

