//
//  MoyaProviderSpec.swift
//  MoyaTests
//
//  Created by Ash Furrow on 2014-09-06.
//  Copyright (c) 2014 Ash Furrow. All rights reserved.
//

import Quick
import Nimble
import Moya

class EndpointSpec: QuickSpec {
    override func spec() {
        describe("an enpoint", { () -> () in
            var endpoint: Endpoint<GitHub>!
            
            beforeEach({ () -> () in
                let target: GitHub = .Zen
                endpoint = Endpoint<GitHub>(URL: url(target), sampleResponse: .Success(target.sampleData), method: Moya.Method.GET, parameters: [String: AnyObject]())
            })
            
            it("returns a new endpoint for endpointByAddingParameters") {
                let message = "I hate it when villains quote Shakespeare."
                let newEndpoint = endpoint.endpointByAddingParameters(["message": message])
                
                let newEndpointMessageObject: AnyObject? = newEndpoint.parameters["message"]
                let newEndpointMessage = newEndpointMessageObject as? String
                expect(newEndpointMessage).to(equal(message))
                //TODO: Compare other properties to ensure they've been copied correctly.
            }
            
            pending("returns a new endpoint for endpointByAddingHTTPHeaderFields") {
                //TODO:
            }
            
            pending("returns a correct URL request") {
                //TODO:
            }
        })
    }
}
