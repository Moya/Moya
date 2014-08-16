//
//  Endpoint.swift
//  Moya
//
//  Created by Ash Furrow on 2014-08-16.
//  Copyright (c) 2014 Ash Furrow. All rights reserved.
//

import Foundation

public typealias EndpointConfiguration = () -> ()
public typealias EndpointSampleResponse = () -> ()

public class Endpoint {
    var URL: String
    var configuration: EndpointConfiguration
    var sampleResponse: EndpointSampleResponse
    
    public init (URL: String, configuration: EndpointConfiguration, sampleResponse: EndpointSampleResponse) {
        self.URL = URL
        self.configuration = configuration
        self.sampleResponse = sampleResponse
    }
}
