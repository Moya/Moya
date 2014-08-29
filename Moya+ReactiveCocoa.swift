//
//  Moya+ReactiveCocoa.swift
//  Moya
//
//  Created by Ash Furrow on 2014-08-22.
//  Copyright (c) 2014 Ash Furrow. All rights reserved.
//

import Foundation

public class ReactiveMoyaProvider<T where T: MoyaTarget>: MoyaProvider<T> {
    override public init(endpointsClosure: MoyaEndpointsClosure, stubResponses: Bool  = false) {
        super.init(endpointsClosure: endpointsClosure, stubResponses: stubResponses)
    }
    
    public func request(token: T, method: Moya.Method, parameters: [String: AnyObject]) -> RACSignal {
        let subject = RACSubject()
        
        request(token, method: method, parameters: parameters) { (object: AnyObject?, error: NSError?) -> () in
            if let error = error {
                subject.sendError(error)
            } else {
                if let object: AnyObject = object {
                    subject.sendNext(object)
                    subject.sendCompleted()
                }
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
