//
//  MoyaProviderIntegrationTests.swift
//  MoyaTests
//
//  Created by Ash Furrow on 2014-08-16.
//  Copyright (c) 2014 Ash Furrow. All rights reserved.
//

import UIKit
import Moya
import Quick
import Nimble

func beIndenticalToResponse(expectedValue: MoyaResponse) -> MatcherFunc<MoyaResponse> {
    return MatcherFunc { actualExpression, failureMessage in
        let instance = actualExpression.evaluate()
        return instance === expectedValue
    }
}

class MoyaProviderIntegrationTests: QuickSpec {
    override func spec() {
        describe("valid endpoints") {
            describe("with live data") {
                describe("a provider", { () -> () in
                    var provider: MoyaProvider<GitHub>!
                    beforeEach {
                        provider = MoyaProvider(endpointsClosure: endpointsClosure)
                    }
                    
                    it("returns real data for zen request") {
                        var message: String?
                        
                        let target: GitHub = .Zen
                        provider.request(target, completion: { (data, statusCode, response, error) in
                            if let data = data {
                                message = NSString(data: data, encoding: NSUTF8StringEncoding)
                            }
                        })
                        
                        expect{message}.toEventuallyNot(beNil(), timeout: 10, pollInterval: 0.1)
                    }
                    
                    it("returns real data for user profile request") {
                        var message: String?
                        
                        let target: GitHub = .UserProfile("ashfurrow")
                        provider.request(target, completion: { (data, statusCode, response, error) in
                            if let data = data {
                                message = NSString(data: data, encoding: NSUTF8StringEncoding)
                            }
                        })
                        
                        expect{message}.toEventuallyNot(beNil(), timeout: 10, pollInterval: 0.1)
                    }
                })
                
                describe("a reactive provider", { () -> () in
                    var provider: ReactiveMoyaProvider<GitHub>!
                    beforeEach {
                        provider = ReactiveMoyaProvider(endpointsClosure: endpointsClosure)
                    }
                    
                    it("returns some data for zen request") {
                        var message: String?
                        
                        let target: GitHub = .Zen
                        provider.request(target).subscribeNext({ (response) -> Void in
                            if let response = response as? MoyaResponse {
                                message = NSString(data: response.data, encoding: NSUTF8StringEncoding)
                            }
                        })
                        
                        expect{message}.toEventuallyNot(beNil(), timeout: 10, pollInterval: 0.1)
                    }
                    
                    it("returns some data for user profile request") {
                        var receivedResponse: NSDictionary?
                        
                        let target: GitHub = .UserProfile("ashfurrow")
                        provider.request(target).subscribeNext({ (response) -> Void in
                            if let response = response as? MoyaResponse {
                                receivedResponse = NSJSONSerialization.JSONObjectWithData(response.data, options: nil, error: nil) as? NSDictionary
                            }
                        })
                        
                        let sampleData = target.sampleData as NSData
                        let sampleResponse: NSDictionary = NSJSONSerialization.JSONObjectWithData(sampleData, options: NSJSONReadingOptions.MutableContainers, error: nil) as NSDictionary
                        expect{receivedResponse}.toEventuallyNot(beNil(), timeout: 10, pollInterval: 0.1)
                    }
                    
                    it("returns identical signals for inflight requests") {
                        let target: GitHub = .Zen
                        let signal1 = provider.request(target)
                        let signal2 = provider.request(target)
                        
                        expect(provider.inflightRequests.count).to(equal(0))
                        
                        var receivedResponse: MoyaResponse!
                        
                        signal1.subscribeNext({ (response) -> Void in
                            receivedResponse = response as? MoyaResponse
                            expect(provider.inflightRequests.count).to(equal(1))
                        })
                        
                        signal2.subscribeNext({ (response) -> Void in
                            expect(receivedResponse).toNot(beNil())
                            expect(receivedResponse).to(beIndenticalToResponse(response as MoyaResponse))
                            expect(provider.inflightRequests.count).to(equal(1))
                        })
                        
                        // Allow for network request to complete
                        expect(provider.inflightRequests.count).toEventually(equal(0), timeout: 10, pollInterval: 0.1)
                    }
                })
            }
        }
    }
}
