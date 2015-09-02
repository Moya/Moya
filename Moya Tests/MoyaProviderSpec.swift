import Quick
import Moya
import Nimble
import Alamofire

class MoyaProviderSpec: QuickSpec {
    override func spec() {
        describe("valid endpoints") {
            describe("with stubbed responses") {
                describe("a provider", {
                    var provider: MoyaProvider<Github>!
                    beforeEach {
                        provider = MoyaProvider<Github>(stubBehavior: MoyaProvider.ImmediateStubbingBehaviour)
                    }
                    
                    it("returns stubbed data for zen request") {
                        var message: String?
                        
                        let target: Github = .Zen
                        provider.request(target) { (data, statusCode, response, error) in
                            if let data = data {
                                message = NSString(data: data, encoding: NSUTF8StringEncoding) as? String
                            }
                        }
                        
                        let sampleData = target.sampleData as NSData
                        expect(message).to(equal(NSString(data: sampleData, encoding: NSUTF8StringEncoding)))
                    }
                    
                    it("returns stubbed data for user profile request") {
                        var message: String?
                        
                        let target: Github = .UserProfile("ashfurrow")
                        provider.request(target) { (data, statusCode, response, error) in
                            if let data = data {
                                message = NSString(data: data, encoding: NSUTF8StringEncoding) as? String
                            }
                        }
                        
                        let sampleData = target.sampleData as NSData
                        expect(message).to(equal(NSString(data: sampleData, encoding: NSUTF8StringEncoding)))
                    }
                    
                    it("returns equivalent Endpoint instances for the same target") {
                        let target: Github = .Zen
                        
                        let endpoint1 = provider.endpoint(target)
                        let endpoint2 = provider.endpoint(target)
                        expect(endpoint1).to(equal(endpoint2))
                    }
                    
                    it("returns a cancellable object when a request is made") {
                        let target: Github = .UserProfile("ashfurrow")
                        
                        let cancellable: Cancellable = provider.request(target) { (_, _, _, _) in }
                        
                        expect(cancellable).toNot(beNil())

                    }

                    it("uses the Alamofire.Manager.sharedInstance by default") {
                        expect(provider.manager).to(beIdenticalTo(Alamofire.Manager.sharedInstance))
                    }

                    it("accepts a custom Alamofire.Manager") {
                        let manager = Manager()
                        let provider = MoyaProvider<Github>(manager: manager)

                        expect(provider.manager).to(beIdenticalTo(manager))
                    }
                })

                it("notifies at the beginning of network requests") {
                    var called = false
                    var provider = MoyaProvider<Github>(stubBehavior: MoyaProvider.ImmediateStubbingBehaviour, networkActivityClosure: { (change) -> () in
                        if change == .Began {
                            called = true
                        }
                    })

                    let target: Github = .Zen
                    provider.request(target) { (data, statusCode, response, error) in }

                    expect(called) == true
                }

                it("notifies at the end of network requests") {
                    var called = false
                    var provider = MoyaProvider<Github>(stubBehavior: MoyaProvider.ImmediateStubbingBehaviour, networkActivityClosure: { (change) -> () in
                        if change == .Ended {
                            called = true
                        }
                    })

                    let target: Github = .Zen
                    provider.request(target) { (data, statusCode, response, error) in }
                    
                    expect(called) == true
                }

                describe("a provider with lazy data", { () -> () in
                    var provider: MoyaProvider<Github>!
                    beforeEach {
                        provider = MoyaProvider<Github>(endpointClosure: lazyEndpointClosure, stubBehavior: MoyaProvider.ImmediateStubbingBehaviour)
                    }

                    it("returns stubbed data for zen request") {
                        var message: String?

                        let target: Github = .Zen
                        provider.request(target) { (data, statusCode, response, error) in
                            if let data = data {
                                message = NSString(data: data, encoding: NSUTF8StringEncoding) as? String
                            }
                        }

                        let sampleData = target.sampleData as NSData
                        expect(message).to(equal(NSString(data: sampleData, encoding: NSUTF8StringEncoding)))
                    }
                })

                it("delays execution when appropriate") {
                    let provider = MoyaProvider<Github>(stubBehavior: MoyaProvider.DelayedStubbingBehaviour(2))

                    let startDate = NSDate()
                    var endDate: NSDate?
                    let target: Github = .Zen
                    waitUntil(timeout: 3) { done in
                        provider.request(target) { (data, statusCode, response, error) in
                            endDate = NSDate()
                            done()
                        }
                        return
                    }

                    expect{
                        return endDate?.timeIntervalSinceDate(startDate)
                    }.to( beGreaterThanOrEqualTo(NSTimeInterval(2)) )
                }

                describe("a provider with a custom endpoint resolver") { () -> () in
                    var provider: MoyaProvider<Github>!
                    var executed = false
                    let newSampleResponse = "New Sample Response"
                    
                    beforeEach {
                        executed = false
                        let endpointResolution = { (endpoint: Endpoint<Github>) -> (NSURLRequest) in
                            executed = true
                            return endpoint.urlRequest
                        }
                        provider = MoyaProvider<Github>(endpointResolver: endpointResolution, stubBehavior: MoyaProvider.ImmediateStubbingBehaviour)
                    }
                    
                    it("executes the endpoint resolver") {
                        let target: Github = .Zen
                        provider.request(target, completion: { (data, statusCode, response, error) in })
                        
                        let sampleData = target.sampleData as NSData
                        expect(executed).to(beTruthy())
                    }
                }    
            }

            describe("with stubbed errors") {
                describe("a provider") { () -> () in
                    var provider: MoyaProvider<Github>!
                    beforeEach {
                        provider = MoyaProvider(endpointClosure: failureEndpointClosure, stubBehavior: MoyaProvider.ImmediateStubbingBehaviour)
                    }
                    
                    it("returns stubbed data for zen request") {
                        var errored = false
                        
                        let target: Github = .Zen
                        provider.request(target) { (object, statusCode, response, error) in
                            if error != nil {
                                errored = true
                            }
                        }
                        
                        let sampleData = target.sampleData as NSData
                        expect(errored).toEventually(beTruthy())
                    }
                    
                    it("returns stubbed data for user profile request") {
                        var errored = false
                        
                        let target: Github = .UserProfile("ashfurrow")
                        provider.request(target) { (object, statusCode, response, error) in
                            if error != nil {
                                errored = true
                            }
                        }
                        
                        let sampleData = target.sampleData as NSData
                        expect{errored}.toEventually(beTruthy(), timeout: 1, pollInterval: 0.1)
                    }
                    
                    it("returns stubbed error data when present") {
                        var errorMessage = ""
                        
                        let target: Github = .UserProfile("ashfurrow")
                        provider.request(target) { (object, statusCode, response, error) in
                            if let object = object {
                                errorMessage = NSString(data: object, encoding: NSUTF8StringEncoding) as! String
                            }
                        }

                        expect{errorMessage}.toEventually(equal("Houston, we have a problem"), timeout: 1, pollInterval: 0.1)
                    }
                }
            }
        }
    }
}
