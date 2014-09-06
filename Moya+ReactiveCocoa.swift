//
//  Moya+ReactiveCocoa.swift
//  Moya
//
//  Created by Ash Furrow on 2014-08-22.
//  Copyright (c) 2014 Ash Furrow. All rights reserved.
//

import Foundation

public class ReactiveMoyaProvider<T where T: MoyaTarget>: MoyaProvider<T> {
    override public init(endpointsClosure: MoyaEndpointsClosure, endpointModifier: MoyaEndpointModification = MoyaProvider.DefaultEnpointModification(), stubResponses: Bool = false) {
        super.init(endpointsClosure: endpointsClosure, endpointModifier: endpointModifier, stubResponses: stubResponses)
    }
    
    public func request(token: T, method: Moya.Method, parameters: [String: AnyObject]) -> RACSignal {
        let subject = RACSubject()
        
        request(token, method: method, parameters: parameters) { (data: NSData?, error: NSError?) -> () in
            if let error = error {
                subject.sendError(error)
            } else {
                if let data = data {
                    subject.sendNext(data)
                }
                subject.sendCompleted()
            }
        }
        
        return subject.publish().autoconnect()
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
