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
                        
                        expect{ message }.toEventually( equal(zenMessage) )
                    }
                    
                    it("returns real data for user profile request") {
                        var message: String?
                        
                        let target: Github = .UserProfile("ashfurrow")
                        provider.request(target) { (data, statusCode, response, error) in
                            if let data = data {
                                message = NSString(data: data, encoding: NSUTF8StringEncoding) as? String
                            }
                        }
                        
                        expect{ message }.toEventually( equal(userMessage) )
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
            }
        }
    }
}
