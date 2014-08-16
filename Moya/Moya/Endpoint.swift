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

public class Endpoint {
    public let URL: String
    let configuration: EndpointConfiguration?
    let sampleResponse: EndpointSampleResponse
    
    public init (URL: String, configuration: EndpointConfiguration?, sampleResponse: EndpointSampleResponse) {
        self.URL = URL
        self.configuration = configuration
        self.sampleResponse = sampleResponse
    }
    
    public convenience init (URL:String, sampleResponse: EndpointSampleResponse) {
        self.init(URL: URL, configuration: nil, sampleResponse: sampleResponse)
    }
}
