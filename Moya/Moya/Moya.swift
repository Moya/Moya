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

public class MoyaProvider {
    public let endpoints: Array<Endpoint>
    let stubResponses: Bool
    lazy var endpointDictionary: [String: Endpoint] = {
        var result = Dictionary<String, Endpoint>()
        for endpoint in self.endpoints {
            let key: String = endpoint.URL
            result[key] = endpoint
        }
        return result
    }()
    
    public init (endpoints: Array<Endpoint>, stubResponses: Bool  = false) {
        self.endpoints = endpoints
        self.stubResponses = stubResponses
    }
    
    public func request (URL: String, completion: MoyaCompletion) {
        let endpoint = endpointDictionary[URL]
        assert(endpoint.hasValue)

        if (stubResponses) {
            let sampleResponse: AnyObject = endpoint!.sampleResponse()
            completion(sampleResponse)
        } else {
            AF.request(.GET, endpoint!.URL)
              .response({(request: NSURLRequest, reponse: NSHTTPURLResponse?, data: AnyObject?, error: NSError?) -> () in
                    completion(data)
              })
        }
    }
}

