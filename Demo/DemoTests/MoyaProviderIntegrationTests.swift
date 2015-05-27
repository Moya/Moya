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
import OHHTTPStubs

func beIndenticalToResponse(expectedValue: MoyaResponse) -> MatcherFunc<MoyaResponse> {
    return MatcherFunc { actualExpression, failureMessage in
        let instance = actualExpression.evaluate()
        return instance === expectedValue
    }
}

class MoyaProviderIntegrationTests: QuickSpec {
    override func spec() {
        let userMessage = NSString(data: GitHub.UserProfile("ashfurrow").sampleData, encoding: NSUTF8StringEncoding)
        let zenMessage = NSString(data: GitHub.Zen.sampleData, encoding: NSUTF8StringEncoding)

        beforeEach { () -> () in
            OHHTTPStubs.stubRequestsPassingTest({$0.URL!.path == "/zen"}) { _ in
                return OHHTTPStubsResponse(data: GitHub.Zen.sampleData, statusCode: 200, headers: nil)
            }

            OHHTTPStubs.stubRequestsPassingTest({$0.URL!.path == "/users/ashfurrow"}) { _ in
                return OHHTTPStubsResponse(data: GitHub.UserProfile("ashfurrow").sampleData, statusCode: 200, headers: nil)
            }
        }

        afterEach { () -> () in
            OHHTTPStubs.removeAllStubs()
        }

        describe("valid endpoints") {
            describe("with live data") {
                describe("a provider") { () -> () in
                    var provider: MoyaProvider<GitHub>!
                    beforeEach {
                        provider = MoyaProvider(endpointsClosure: endpointsClosure)
                        return
                    }
                    
                    it("returns real data for zen request") {
                        var message: String?
                        
                        let target: GitHub = .Zen
                        provider.request(target) { (data, statusCode, response, error) in
                            if let data = data {
                                message = NSString(data: data, encoding: NSUTF8StringEncoding) as? String
                            }
                        }
                        
                        expect{message}.toEventually( equal(zenMessage) )
                    }
                    
                    it("returns real data for user profile request") {
                        var message: String?
                        
                        let target: GitHub = .UserProfile("ashfurrow")
                        provider.request(target) { (data, statusCode, response, error) in
                            if let data = data {
                                message = NSString(data: data, encoding: NSUTF8StringEncoding) as? String
                            }
                        }
                        
                        expect{message}.toEventually( equal(userMessage) )
                    }
                    
                    it("returns an error when cancelled") {
                        var receivedError: NSError?
                        
                        let target: GitHub = .UserProfile("ashfurrow")
                        let token = provider.request(target) { (data, statusCode, response, error) in
                            receivedError = error
                        }
                        token.cancel()
                        
                        expect(receivedError).toEventuallyNot( beNil() )
                    }
                }

                describe("a provider with network activity closures") {
                    it("notifies at the beginning of network requests") {
                        var called = false
                        var provider = MoyaProvider(endpointsClosure: endpointsClosure, networkActivityClosure: { (change) -> () in
                            if change == .Began {
                                called = true
                            }
                        })

                        let target: GitHub = .Zen
                        provider.request(target) { (data, statusCode, response, error) in }

                        expect(called).toEventually( beTrue() )
                    }

                    it("notifies at the end of network requests") {
                        var called = false
                        var provider = MoyaProvider(endpointsClosure: endpointsClosure, networkActivityClosure: { (change) -> () in
                            if change == .Ended {
                                called = true
                            }
                        })

                        let target: GitHub = .Zen
                        provider.request(target) { (data, statusCode, response, error) in }

                        expect(called).toEventually( beTrue() )
                    }
                }
                
                describe("a reactive provider") { () -> () in
                    var provider: ReactiveMoyaProvider<GitHub>!
                    beforeEach {
                        provider = ReactiveMoyaProvider(endpointsClosure: endpointsClosure)
                    }
                    
                    it("returns some data for zen request") {
                        var message: String?
                        
                        let target: GitHub = .Zen
                        provider.request(target).subscribeNext { (response) -> Void in
                            if let response = response as? MoyaResponse {
                                message = NSString(data: response.data, encoding: NSUTF8StringEncoding) as? String
                            }
                        }

                        expect{message}.toEventually( equal(zenMessage) )
                    }
                    
                    it("returns some data for user profile request") {
                        var message: String?
                        
                        let target: GitHub = .UserProfile("ashfurrow")
                        provider.request(target).subscribeNext { (response) -> Void in
                            if let response = response as? MoyaResponse {
                                message = NSString(data: response.data, encoding: NSUTF8StringEncoding) as? String
                            }
                        }

                        expect{message}.toEventually( equal(userMessage) )
                    }
                    
                    it("returns identical signals for inflight requests") {
                        let target: GitHub = .Zen
                        let signal1 = provider.request(target)
                        let signal2 = provider.request(target)
                        
                        expect(provider.inflightRequests.count).to(equal(0))
                        
                        var receivedResponse: MoyaResponse!
                        
                        signal1.subscribeNext { (response) -> Void in
                            receivedResponse = response as? MoyaResponse
                            expect(provider.inflightRequests.count).to(equal(1))
                        }
                        
                        signal2.subscribeNext { (response) -> Void in
                            expect(receivedResponse).toNot(beNil())
                            expect(receivedResponse).to(beIndenticalToResponse( response as! MoyaResponse) )
                            expect(provider.inflightRequests.count).to(equal(1))
                        }
                        
                        // Allow for network request to complete
                        expect(provider.inflightRequests.count).toEventually( equal(0) )
                    }
                }
            }
        }
    }
}
