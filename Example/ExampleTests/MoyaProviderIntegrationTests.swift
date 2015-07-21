import UIKit
import Alamofire
import Moya
import ReactiveMoya
import ReactiveCocoa
import RxMoya
import Quick
import Nimble
import OHHTTPStubs

func beIdenticalToResponse(expectedValue: MoyaResponse) -> MatcherFunc<MoyaResponse> {
    return MatcherFunc { actualExpression, failureMessage in
        if let instance = actualExpression.evaluate() {
            return instance === expectedValue
        } else {
            return false
        }
    }
}

class MoyaProviderIntegrationTests: QuickSpec {
    override func spec() {
        let userMessage = NSString(data: Github.UserProfile("ashfurrow").sampleData, encoding: NSUTF8StringEncoding)
        let zenMessage = NSString(data: Github.Zen.sampleData, encoding: NSUTF8StringEncoding)

        beforeEach { () -> () in
            OHHTTPStubs.stubRequestsPassingTest({$0.URL!.path == "/zen"}) { _ in
                return OHHTTPStubsResponse(data: Github.Zen.sampleData, statusCode: 200, headers: nil)
            }

            OHHTTPStubs.stubRequestsPassingTest({$0.URL!.path == "/users/ashfurrow"}) { _ in
                return OHHTTPStubsResponse(data: Github.UserProfile("ashfurrow").sampleData, statusCode: 200, headers: nil)
            }
        }

        afterEach { () -> () in
            OHHTTPStubs.removeAllStubs()
        }

        describe("valid endpoints") {
            describe("with live data") {
                describe("a provider") { () -> () in
                    var provider: MoyaProvider<Github>!
                    beforeEach {
                        provider = MoyaProvider<Github>()
                        return
                    }
                    
                    it("returns real data for zen request") {
                        var message: String?
                        
                        let target: Github = .Zen
                        provider.request(target) { (data, statusCode, response, error) in
                            if let data = data {
                                message = NSString(data: data, encoding: NSUTF8StringEncoding) as? String
                            }
                        }
                        
                        expect{message}.toEventually( equal(zenMessage) )
                    }
                    
                    it("returns real data for user profile request") {
                        var message: String?
                        
                        let target: Github = .UserProfile("ashfurrow")
                        provider.request(target) { (data, statusCode, response, error) in
                            if let data = data {
                                message = NSString(data: data, encoding: NSUTF8StringEncoding) as? String
                            }
                        }
                        
                        expect{message}.toEventually( equal(userMessage) )
                    }
                    
                    it("returns an error when cancelled") {
                        var receivedError: NSError?
                        
                        let target: Github = .UserProfile("ashfurrow")
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
                        var provider = MoyaProvider<Github>(networkActivityClosure: { (change) -> () in
                            if change == .Began {
                                called = true
                            }
                        })

                        let target: Github = .Zen
                        provider.request(target) { (data, statusCode, response, error) in }

                        expect(called).toEventually( beTrue() )
                    }

                    it("notifies at the end of network requests") {
                        var called = false
                        var provider = MoyaProvider<Github>(networkActivityClosure: { (change) -> () in
                            if change == .Ended {
                                called = true
                            }
                        })

                        let target: Github = .Zen
                        provider.request(target) { (data, statusCode, response, error) in }

                        expect(called).toEventually( beTrue() )
                    }
                }
                
                describe("a reactive provider") { () -> () in
                    var provider: ReactiveCocoaMoyaProvider<Github>!
                    beforeEach {
                        provider = ReactiveCocoaMoyaProvider<Github>()
                    }
                    
                    describe("using RAC 2.0") {
                        it("returns some data for zen request") {
                            var message: String?
                            
                            let target: Github = .Zen
                            provider.request(target).subscribeNext { (response) -> Void in
                                if let response = response as? MoyaResponse {
                                    message = NSString(data: response.data, encoding: NSUTF8StringEncoding) as? String
                                }
                            }

                            expect{message}.toEventually( equal(zenMessage) )
                        }
                        
                        it("returns some data for user profile request") {
                            var message: String?
                            
                            let target: Github = .UserProfile("ashfurrow")
                            provider.request(target).subscribeNext { (response) -> Void in
                                if let response = response as? MoyaResponse {
                                    message = NSString(data: response.data, encoding: NSUTF8StringEncoding) as? String
                                }
                            }

                            expect{message}.toEventually( equal(userMessage) )
                        }
                        
                        it("returns identical signals for inflight requests") {
                            let target: Github = .Zen
                            let signal1: RACSignal = provider.request(target)
                            let signal2: RACSignal = provider.request(target)
                            
                            expect(provider.inflightRequests.count).to(equal(0))
                            
                            var receivedResponse: MoyaResponse!
                            
                            signal1.subscribeNext { (response) -> Void in
                                receivedResponse = response as? MoyaResponse
                                expect(provider.inflightRequests.count).to(equal(1))
                            }
                            
                            signal2.subscribeNext { (response) -> Void in
                                expect(receivedResponse).toNot(beNil())
                                expect(receivedResponse).to(beIdenticalToResponse( response as! MoyaResponse) )
                                expect(provider.inflightRequests.count).to(equal(1))
                            }
                            
                            // Allow for network request to complete
                            expect(provider.inflightRequests.count).toEventually( equal(0) )
                        }
                    }
                    
                    describe("using RAC 3.0") {
                        it("returns some data for zen request") {
                            var message: String?
                            
                            let target: Github = .Zen
                            provider.requestString(target)
                                |> start(next: { (response: String) in
                                    message = response
                                })
                            
                            expect { message }.toEventually( equal(zenMessage) )
                        }
                        
                        it("returns some data for user profile request") {
                            var message: String?
                            
                            let target: Github = .UserProfile("ashfurrow")
                            provider.requestString(target)
                                |> start(next: { (dictionary: String) in
                                    message = dictionary
                                })
                            
                            expect { message }.toEventually( equal(userMessage) )
                        }
                        
                        it("returns identical signals for inflight requests") {
                            let target: Github = .Zen
                            let signal1: SignalProducer<MoyaResponse, NSError> = provider.request(target)
                            let signal2: SignalProducer<MoyaResponse, NSError> = provider.request(target)
                            
                            expect(provider.inflightRequests.count).to( equal(1) )
                            
                            var receivedResponse: MoyaResponse!
                            
                            signal1
                                |> start(next: { (response: MoyaResponse) in
                                    receivedResponse = response
                                    expect(provider.inflightRequests.count).to( equal(1) )
                                })
                            
                            signal2
                                |> start(next: { (response: MoyaResponse) in
                                    expect(receivedResponse).toNot( beNil() )
                                    expect(receivedResponse).to( beIdenticalToResponse(response) )
                                    expect(provider.inflightRequests.count).to( equal(0) )
                                })
                            
                            expect(provider.inflightRequests.count).toEventually( equal(0) )
                        }
                    }
                }
            }
        }
    }
}
