//
//  MoyaProviderSpec.swift
//  MoyaTests
//
//  Created by Ash Furrow on 2014-09-06.
//  Copyright (c) 2014 Ash Furrow. All rights reserved.
//

import Quick
import Moya
import Nimble

extension Moya.ParameterEncoding: Equatable {
}

public func ==(lhs: Moya.ParameterEncoding, rhs: Moya.ParameterEncoding) -> Bool {
    switch (lhs, rhs) {
    case (.URL, .URL):
        return true
    case (.JSON, .JSON):
        return true
    case (.PropertyList(_), .PropertyList(_)):
        return true
    case (.Custom(_), .Custom(_)):
        return true
    default:
        return false
    }
}

class EndpointSpec: QuickSpec {
    override func spec() {
        describe("an endpoint", { () -> () in
            var endpoint: Endpoint<GitHub>!
            
            beforeEach({ () -> () in
                let target: GitHub = .Zen
                let parameters = ["Nemesis": "Harvey"] as [String: AnyObject]
                let headerFields = ["Title": "Dominar"] as [String: AnyObject]
                endpoint = Endpoint<GitHub>(URL: url(target), sampleResponse: .Success(200, target.sampleData), method: Moya.Method.GET, parameters: parameters, parameterEncoding: .JSON, httpHeaderFields: headerFields)
            })
            
            it("returns a new endpoint for endpointByAddingParameters") {
                let message = "I hate it when villains quote Shakespeare."
                let newEndpoint = endpoint.endpointByAddingParameters(["message": message])
                
                let newEndpointMessageObject: AnyObject? = newEndpoint.parameters["message"]
                let newEndpointMessage = newEndpointMessageObject as? String
                // Make sure our closure updated the sample response, as proof that it can modify the Endpoint
                expect(newEndpointMessage).to(equal(message))
                
                // Compare other properties to ensure they've been copied correctly
                expect(newEndpoint.URL).to(equal(endpoint.URL))
                expect(newEndpoint.method).to(equal(endpoint.method))
                expect(newEndpoint.parameterEncoding).to(equal(endpoint.parameterEncoding))
                expect(newEndpoint.httpHeaderFields.count).to(equal(endpoint.httpHeaderFields.count))
            }
            
            it("returns a new endpoint for endpointByAddingHTTPHeaderFields") {
                let agent = "Zalbinian"
                let newEndpoint = endpoint.endpointByAddingHTTPHeaderFields(["User-Agent": agent])
                
                let newEndpointAgentObject: AnyObject? = newEndpoint.httpHeaderFields["User-Agent"]
                let newEndpointAgent = newEndpointAgentObject as? String
                // Make sure our closure updated the sample response, as proof that it can modify the Endpoint
                expect(newEndpointAgent).to(equal(agent))
                
                // Compare other properties to ensure they've been copied correctly
                expect(newEndpoint.URL).to(equal(endpoint.URL))
                expect(newEndpoint.method).to(equal(endpoint.method))
                expect(newEndpoint.parameters.count).to(equal(endpoint.parameters.count))
                expect(newEndpoint.parameterEncoding).to(equal(endpoint.parameterEncoding))
            }
            
            it("returns a correct URL request") {
                let request = endpoint.urlRequest
                expect(request.URL.absoluteString).to(equal("https://api.github.com/zen"))
                expect(NSString(data: request.HTTPBody!, encoding: 4)).to(equal("{\"Nemesis\":\"Harvey\"}"))
                let titleObject: AnyObject? = endpoint.httpHeaderFields["Title"]
                let title = titleObject as? String
                expect(title).to(equal("Dominar"))
            }
        })
    }
}
