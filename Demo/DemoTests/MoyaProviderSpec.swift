//
//  MoyaProviderSpec.swift
//  MoyaTests
//
//  Created by Ash Furrow on 2014-08-16.
//  Copyright (c) 2014 Ash Furrow. All rights reserved.
//

import Quick
import Moya
import Nimble

class MoyaProviderSpec: QuickSpec {
    override func spec() {
        describe("valid endpoints") {
            describe("with stubbed responses") {
                describe("a provider", { () -> () in
                    var provider: MoyaProvider<GitHub>!
                    beforeEach {
                        provider = MoyaProvider(endpointsClosure: endpointsClosure, stubResponses: true)
                    }
                    
                    it("returns stubbed data for zen request") {
                        var message: String?
                        
                        let target: GitHub = .Zen
                        provider.request(target, completion: { (data, statusCode, response, error) in
                            if let data = data {
                                message = NSString(data: data, encoding: NSUTF8StringEncoding)
                            }
                        })
                        
                        let sampleData = target.sampleData as NSData
                        expect(message).to(equal(NSString(data: sampleData, encoding: NSUTF8StringEncoding)))
                    }
                    
                    it("returns stubbed data for user profile request") {
                        var message: String?
                        
                        let target: GitHub = .UserProfile("ashfurrow")
                        provider.request(target, completion: { (data, statusCode, response, error) in
                            if let data = data {
                                message = NSString(data: data, encoding: NSUTF8StringEncoding)
                            }
                        })
                        
                        let sampleData = target.sampleData as NSData
                        expect(message).to(equal(NSString(data: sampleData, encoding: NSUTF8StringEncoding)))
                    }
                    
                    it("returns equivalent Endpoint instances for the same target") {
                        let target: GitHub = .Zen
                        
                        let endpoint1 = provider.endpoint(target, method: Moya.DefaultMethod(), parameters: Moya.DefaultParameters())
                        let endpoint2 = provider.endpoint(target, method: Moya.DefaultMethod(), parameters: Moya.DefaultParameters())
                        expect(endpoint1).to(equal(endpoint2))
                    }
                })

                describe("a provider with lazy data", { () -> () in
                    var provider: MoyaProvider<GitHub>!
                    beforeEach {
                        provider = MoyaProvider(endpointsClosure: lazyEndpointsClosure, stubResponses: true)
                    }

                    it("returns stubbed data for zen request") {
                        var message: String?

                        let target: GitHub = .Zen
                        provider.request(target, completion: { (data, statusCode, response, error) in
                            if let data = data {
                                message = NSString(data: data, encoding: NSUTF8StringEncoding)
                            }
                        })

                        let sampleData = target.sampleData as NSData
                        expect(message).to(equal(NSString(data: sampleData, encoding: NSUTF8StringEncoding)))
                    }
                })

                it("delays execution when appropriate") {
                    let closure = { (target: GitHub) -> (Moya.StubbedBehavior) in
                        return .Delayed(seconds: 2)
                    }

                    let provider = MoyaProvider(endpointsClosure: endpointsClosure, stubResponses: true, stubBehavior: closure)

                    let startDate = NSDate()
                    var endDate: NSDate?
                    let target: GitHub = .Zen
                    waitUntil(timeout: 3){ done in
                        provider.request(target, completion: { (data, statusCode, response, error) in
                            endDate = NSDate()
                            done()
                        })
                    }

                    expect{
                        return endDate?.timeIntervalSinceDate(startDate)
                    }.to( beGreaterThanOrEqualTo(NSTimeInterval(2)) )
                }

                describe("a provider with a custom endpoint resolver", { () -> () in
                    var provider: MoyaProvider<GitHub>!
                    var executed = false
                    let newSampleResponse = "New Sample Response"
                    
                    beforeEach {
                        executed = false
                        let endpointResolution = { (endpoint: Endpoint<GitHub>) -> (NSURLRequest) in
                            executed = true
                            return endpoint.urlRequest
                        }
                        provider = MoyaProvider(endpointsClosure: endpointsClosure, endpointResolver: endpointResolution, stubResponses: true)
                    }
                    
                    it("executes the endpoint resolver") {
                        let target: GitHub = .Zen
                        provider.request(target, completion: { (data, statusCode, response, error) in })
                        
                        let sampleData = target.sampleData as NSData
                        expect(executed).to(beTruthy())
                    }
                })
                
                describe("a reactive provider", { () -> () in
                    var provider: ReactiveMoyaProvider<GitHub>!
                    beforeEach {
                        provider = ReactiveMoyaProvider(endpointsClosure: endpointsClosure, stubResponses: true)
                    }
                    
                    it("returns a MoyaResponse object") {
                        var called = false
                        
                        provider.request(.Zen).subscribeNext({ (object) -> Void in
                            if let response = object as? MoyaResponse {
                                called = true
                            }
                        })
                        
                        expect(called).to(beTruthy())
                    }
                    
                    it("returns stubbed data for zen request") {
                        var message: String?
                        
                        let target: GitHub = .Zen
                        provider.request(target).subscribeNext({ (object) -> Void in
                            if let response = object as? MoyaResponse {
                                message = NSString(data: response.data, encoding: NSUTF8StringEncoding)
                            }
                        })
                        
                        let sampleData = target.sampleData as NSData
                        expect(message).toNot(beNil())
                    }
                    
                    it("returns correct data for user profile request") {
                        var receivedResponse: NSDictionary?
                        
                        let target: GitHub = .UserProfile("ashfurrow")
                        provider.request(target).subscribeNext({ (object) -> Void in
                            if let response = object as? MoyaResponse {
                                receivedResponse = NSJSONSerialization.JSONObjectWithData(response.data, options: nil, error: nil) as? NSDictionary
                            }
                        })
                        
                        let sampleData = target.sampleData as NSData
                        let sampleResponse: NSDictionary = NSJSONSerialization.JSONObjectWithData(sampleData, options: nil, error: nil) as NSDictionary
                        expect(receivedResponse).toNot(beNil())
                    }
                    
                    it("returns identical signals for inflight requests") {
                        let target: GitHub = .Zen
                        
                        var response: MoyaResponse!
                        
                        // The synchronous nature of stubbed responses makes this kind of tricky. We use the
                        // subscribeNext closure to get the provider into a state where the signal has been
                        // added to the inflightRequests dictionary. Then we ask for an identical request,
                        // which should return the same signal. We can't *test* those signals equivalency 
                        // due to the use of RACSignal.defer, but we can check if the number of inflight
                        // requests went up or not.
                        
                        let outerSignal = provider.request(target)
                        outerSignal.subscribeNext({ (object) -> Void in
                            response = object as? MoyaResponse
                            expect(provider.inflightRequests.count).to(equal(1))
                            
                            // Create a new signal and force subscription, so that the inflightRequests dictionary is accessed.
                            let innerSignal = provider.request(target)
                            innerSignal.subscribeNext({ (object) -> Void in
                                // nop
                            })
                            expect(provider.inflightRequests.count).to(equal(1))
                        })
                        
                        expect(provider.inflightRequests.count).to(equal(0))
                    }
                })
            }
            
            describe("with stubbed errors") {
                describe("a provider", { () -> () in
                    var provider: MoyaProvider<GitHub>!
                    beforeEach {
                        provider = MoyaProvider(endpointsClosure: failureEndpointsClosure, stubResponses: true)
                    }
                    
                    it("returns stubbed data for zen request") {
                        var errored = false
                        
                        let target: GitHub = .Zen
                        provider.request(target, completion: { (object, statusCode, response, error) in
                            if error != nil {
                                errored = true
                            }
                        })
                        
                        let sampleData = target.sampleData as NSData
                        expect(errored).toEventually(beTruthy())
                    }
                    
                    it("returns stubbed data for user profile request") {
                        var errored = false
                        
                        let target: GitHub = .UserProfile("ashfurrow")
                        provider.request(target, completion: { (object, statusCode, response, error) in
                            if error != nil {
                                errored = true
                            }
                        })
                        
                        let sampleData = target.sampleData as NSData
                        expect{errored}.toEventually(beTruthy(), timeout: 1, pollInterval: 0.1)
                    }
                    
                    it("returns stubbed error data when present") {
                        var errorMessage = ""
                        
                        let target: GitHub = .UserProfile("ashfurrow")
                        provider.request(target, completion: { (object, statusCode, response, error) in
                            if let object = object {
                                errorMessage = NSString(data: object, encoding: NSUTF8StringEncoding)!
                            }
                        })

                        expect{errorMessage}.toEventually(equal("Houston, we have a problem"), timeout: 1, pollInterval: 0.1)
                    }
                })
                
                describe("a reactive provider", { () -> () in
                    var provider: ReactiveMoyaProvider<GitHub>!
                    beforeEach {
                        provider = ReactiveMoyaProvider(endpointsClosure: failureEndpointsClosure, stubResponses: true)
                    }
                    
                    it("returns stubbed data for zen request") {
                        var errored = false
                        
                        let target: GitHub = .Zen
                        provider.request(target).subscribeError({ (error) -> Void in
                            errored = true
                        })
                        
                        expect(errored).to(beTruthy())
                    }
                    
                    it("returns correct data for user profile request") {
                        var errored = false
                        
                        let target: GitHub = .UserProfile("ashfurrow")
                        provider.request(target).subscribeError({ (error) -> Void in
                            errored = true
                        })
                        
                        expect(errored).to(beTruthy())
                    }
                })

                describe("a failing reactive provider") {
                    var provider: ReactiveMoyaProvider<GitHub>!
                    beforeEach {
                        provider = ReactiveMoyaProvider(endpointsClosure: failureEndpointsClosure, stubResponses: true)
                    }

                    it("returns the HTTP status code as the error code") {
                        var code: Int?

                        provider.request(.Zen).subscribeError({ (error) -> Void in
                            code = error.code
                        })
                        
                        expect(code).toNot(beNil())
                        expect(code).to(equal(401))
                    }
                }
            }
        }
    }
}
