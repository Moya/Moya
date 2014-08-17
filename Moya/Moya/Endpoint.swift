//
//  Endpoint.swift
//  Moya
//
//  Created by Ash Furrow on 2014-08-16.
//  Copyright (c) 2014 Ash Furrow. All rights reserved.
//

import Foundation

public typealias EndpointConfiguration = () -> ()
public typealias EndpointSampleResponse = () -> (AnyObject)

public class Endpoint<T: Hashable> {
    public let URL: String
    let sampleResponse: EndpointSampleResponse
    
    public init (URL: String, sampleResponse: EndpointSampleResponse) {
        self.URL = URL
        self.sampleResponse = sampleResponse
        
    }
}
