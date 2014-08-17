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
    
    public init (URL: String, configuration: EndpointConfiguration?, sampleResponse: EndpointSampleResponse) {
        self.URL = URL
        self.sampleResponse = sampleResponse
    }
    
    public convenience init (URL:String, sampleResponse: EndpointSampleResponse) {
        self.init(URL: URL, configuration: nil, sampleResponse: sampleResponse)
    }
}
