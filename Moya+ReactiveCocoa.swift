//
//  Moya+ReactiveCocoa.swift
//  Moya
//
//  Created by Ash Furrow on 2014-08-22.
//  Copyright (c) 2014 Ash Furrow. All rights reserved.
//

import Foundation

public class ReactiveMoyaProvider<T where T: MoyaTarget>: MoyaProvider<T> {
    public var inflightRequests = Dictionary<Endpoint<T>, RACSignal>()
    
    override public init(endpointsClosure: MoyaEndpointsClosure, endpointModifier: MoyaEndpointModification = MoyaProvider.DefaultEnpointModification(), stubResponses: Bool = false) {
        super.init(endpointsClosure: endpointsClosure, endpointModifier: endpointModifier, stubResponses: stubResponses)
    }
    
    public func request(token: T, method: Moya.Method, parameters: [String: AnyObject]) -> RACSignal {
        let endpoint = self.endpoint(token, method: method, parameters: parameters)
        
        if let existingSignal = inflightRequests[endpoint] {
            return existingSignal
        }
        
        // weak self just for best practices – RACSignal will take care of any retain cycles anyway,
        // and we're connecting immediately (below), so self in the block will always be non-nil
        let signal = RACSignal.createSignal({ [weak self] (subscriber) -> RACDisposable! in
            self?.request(token, method: method, parameters: parameters) { (data: NSData?, error: NSError?) -> () in
                if let error = error {
                    subscriber.sendError(error)
                } else {
                    if let data = data {
                        subscriber.sendNext(data)
                    }
                    subscriber.sendCompleted()
                }
            }
            
            return nil
        }).publish().autoconnect()
        
        objc_sync_enter(self)
        self.inflightRequests[endpoint] = signal
        objc_sync_exit(self)
        
        let removeSignal = { [weak self] () -> Void in
            // Once the signal
            if let weakSelf = self {
                objc_sync_enter(weakSelf)
                weakSelf.inflightRequests[endpoint] = nil
                objc_sync_exit(weakSelf)
            }
        }
        
        // Connect immediately, immitating the behaviour of our superclass
        signal.subscribeError({ (_) -> Void in
            removeSignal()
        }, completed: { () -> Void in
            removeSignal()
        })
        
        return signal
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

public func ==<T>(lhs: Endpoint<T>, rhs: Endpoint<T>) -> Bool {
    return lhs.urlRequest.isEqual(rhs.urlRequest)
}

extension Endpoint: Equatable, Hashable {
    public var hashValue: Int {
        return urlRequest.hash
    }
}
