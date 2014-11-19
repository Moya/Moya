//
//  Moya+ReactiveCocoa.swift
//  Moya
//
//  Created by Ash Furrow on 2014-08-22.
//  Copyright (c) 2014 Ash Furrow. All rights reserved.
//

import Foundation
import ReactiveCocoa

public class MoyaResponse {
    public let statusCode: Int
    public let data: NSData
    public let response: NSURLResponse?

    public init(statusCode: Int, data: NSData, response: NSURLResponse?) {
        self.statusCode = statusCode
        self.data = data
        self.response = response
    }
}

extension MoyaResponse: Printable, DebugPrintable {
    public var description: String {
        return "Status Code: \(statusCode), Data Length: \(data.length)"
    }
    
    public var debugDescription: String {
        return description
    }
}

/// Subclass of MoyaProvider that returns RACSignal instances when requests are made. Much better than using completion closures.
public class ReactiveMoyaProvider<T where T: MoyaTarget>: MoyaProvider<T> {
    /// Current requests that have not completed or errored yet.
    /// Note: Do not access this directly. It is public only for unit-testing purposes (sigh).
    public var inflightRequests = Dictionary<Endpoint<T>, RACSignal>()
    
    /// Initializes a reactive provider.
    override public init(endpointsClosure: MoyaEndpointsClosure, endpointResolver: MoyaEndpointResolution = MoyaProvider.DefaultEnpointResolution(), stubResponses: Bool = false) {
        super.init(endpointsClosure: endpointsClosure, endpointResolver: endpointResolver, stubResponses: stubResponses)
    }
    
    /// Designated request-making method.
    public func request(token: T, method: Moya.Method, parameters: [String: AnyObject]) -> RACSignal {
        let endpoint = self.endpoint(token, method: method, parameters: parameters)
        
        // weak self just for best practices – RACSignal will take care of any retain cycles anyway,
        // and we're connecting immediately (below), so self in the block will always be non-nil

        return RACSignal.defer { [weak self] () -> RACSignal! in
            
            if let existingSignal = self?.inflightRequests[endpoint] {
                return existingSignal
            }
            
            let signal = RACSignal.createSignal({ (subscriber) -> RACDisposable! in
                self?.request(token, method: method, parameters: parameters) { (data, statusCode, response, error) -> () in
                    if let error = error {
                        if let statusCode = statusCode {
                            subscriber.sendError(NSError(domain: error.domain, code: statusCode, userInfo: error.userInfo))
                        } else {
                            subscriber.sendError(error)
                        }
                    } else {
                        if let data = data {
                            subscriber.sendNext(MoyaResponse(statusCode: statusCode!, data: data, response: response))
                        }
                        subscriber.sendCompleted()
                    }
                }
                
                return RACDisposable(block: { () -> Void in
                    if let weakSelf = self {
                        objc_sync_enter(weakSelf)
                        weakSelf.inflightRequests[endpoint] = nil
                        objc_sync_exit(weakSelf)
                    }
                })
            }).publish().autoconnect()
            
            if let weakSelf = self {
                objc_sync_enter(weakSelf)
                weakSelf.inflightRequests[endpoint] = signal
                objc_sync_exit(weakSelf)
            }
            
            return signal
        }
    }
    
    public func request(token: T, parameters: [String: AnyObject]) -> RACSignal {
        return request(token, method: Moya.DefaultMethod(), parameters: parameters)
    }
    
    public func request(token: T, method: Moya.Method) -> RACSignal {
        return request(token, method: method, parameters: Moya.DefaultParameters())
    }
    
    public func request(token: T) -> RACSignal {
        return request(token, method: Moya.DefaultMethod())
    }
}

/// Required for making Endpoint conform to Equatable.
public func ==<T>(lhs: Endpoint<T>, rhs: Endpoint<T>) -> Bool {
    return lhs.urlRequest.isEqual(rhs.urlRequest)
}

/// Required for using Endpoint as a key type in a Dictionary.
extension Endpoint: Equatable, Hashable {
    public var hashValue: Int {
        return urlRequest.hash
    }
}
