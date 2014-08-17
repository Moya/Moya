//
//  Moya.swift
//  Moya
//
//  Created by Ash Furrow on 2014-08-16.
//  Copyright (c) 2014 Ash Furrow. All rights reserved.
//

import Foundation

public class Moya {
    
}

public typealias MoyaCompletion = (AnyObject?) -> ()

public class MoyaProvider<T: Hashable> {
    public typealias MoyaEndpointsClosure = (T) -> (Endpoint<T>)
    public let endpointsClosure: MoyaEndpointsClosure
    let stubResponses: Bool
    
    public init (endpointsClosure: MoyaEndpointsClosure, stubResponses: Bool  = false) {
        self.endpointsClosure = endpointsClosure
        self.stubResponses = stubResponses
    }
    
    public func request (token: T, completion: MoyaCompletion) {
        let endpoint = endpointsClosure(token)

        if (stubResponses) {
            let sampleResponse: AnyObject = endpoint.sampleResponse()
            completion(sampleResponse)
        } else {
            AF.request(.GET, endpoint.URL)
              .response({(request: NSURLRequest, reponse: NSHTTPURLResponse?, data: AnyObject?, error: NSError?) -> () in
                    completion(data)
              })
        }
    }
}

