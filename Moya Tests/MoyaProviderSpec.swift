// Testing frameworks
import Quick
import Nimble

// Reactive Moya Dependencies
import ReactiveCocoa
import RxSwift

// Moya variations
import Moya
import ReactiveMoya
import RxMoya

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
                
                describe("a reactive provider", { () -> () in
                    var provider: ReactiveCocoaMoyaProvider<Github>!
                    beforeEach {
                        provider = ReactiveCocoaMoyaProvider<Github>(stubBehavior: MoyaProvider.ImmediateStubbingBehaviour)
                    }
                    
                    it("returns a MoyaResponse object") {
                        var called = false
                        
                        provider.request(.Zen).subscribeNext { (object) -> Void in
                            if let response = object as? MoyaResponse {
                                called = true
                            }
                        }
                        
                        expect(called).to(beTruthy())
                    }
                    
                    it("returns stubbed data for zen request") {
                        var message: String?
                        
                        let target: Github = .Zen
                        provider.request(target).subscribeNext { (object) -> Void in
                            if let response = object as? MoyaResponse {
                                message = NSString(data: response.data, encoding: NSUTF8StringEncoding) as? String
                            }
                        }
                        
                        let sampleData = target.sampleData as NSData
                        expect(message).toNot(beNil())
                    }
                    
                    it("returns correct data for user profile request") {
                        var receivedResponse: NSDictionary?
                        
                        let target: Github = .UserProfile("ashfurrow")
                        provider.request(target).subscribeNext { (object) -> Void in
                            if let response = object as? MoyaResponse {
                                receivedResponse = NSJSONSerialization.JSONObjectWithData(response.data, options: nil, error: nil) as? NSDictionary
                            }
                        }
                        
                        let sampleData = target.sampleData as NSData
                        let sampleResponse: NSDictionary = NSJSONSerialization.JSONObjectWithData(sampleData, options: nil, error: nil) as! NSDictionary
                        expect(receivedResponse).toNot(beNil())
                    }
                    
                    it("returns identical signals for inflight requests") {
                        let target: Github = .Zen
                        
                        var response: MoyaResponse!
                        
                        // The synchronous nature of stubbed responses makes this kind of tricky. We use the
                        // subscribeNext closure to get the provider into a state where the signal has been
                        // added to the inflightRequests dictionary. Then we ask for an identical request,
                        // which should return the same signal. We can't *test* those signals equivalency 
                        // due to the use of RACSignal.defer, but we can check if the number of inflight
                        // requests went up or not.
                        
                        let outerSignal: RACSignal = provider.request(target)
                        outerSignal.subscribeNext { (object) -> Void in
                            response = object as? MoyaResponse
                            expect(provider.inflightRequests.count).to(equal(1))
                            
                            // Create a new signal and force subscription, so that the inflightRequests dictionary is accessed.
                            let innerSignal: RACSignal = provider.request(target)
                            innerSignal.subscribeNext { (object) -> Void in
                                // nop
                            }
                            expect(provider.inflightRequests.count).to(equal(1))
                        }
                        
                        expect(provider.inflightRequests.count).to(equal(0))
                    }
                })
                
                describe("a RxSwift provider", { () -> () in
                    var provider: RxMoyaProvider<Github>!
                    
                    beforeEach {
                        provider = RxMoyaProvider(stubBehavior: MoyaProvider.ImmediateStubbingBehaviour)
                    }
                    
                    it("returns a MoyaResponse object") {
                        var called = false
                        
                        provider.request(.Zen) >- subscribeNext { (object) -> Void in
                            called = true
                        }
                        
                        expect(called).to(beTruthy())
                    }
                    
                    it("returns stubbed data for zen request") {
                        var message: String?
                        
                        let target: Github = .Zen
                        provider.request(target) >- subscribeNext { (response) -> Void in
                            message = NSString(data: response.data, encoding: NSUTF8StringEncoding) as? String
                        }
                        
                        let sampleString = NSString(data: (target.sampleData as NSData), encoding: NSUTF8StringEncoding)
                        expect(message).to(equal(sampleString))
                    }

                    it("returns correct data for user profile request") {
                        var receivedResponse: NSDictionary?
                        
                        let target: Github = .UserProfile("ashfurrow")
                        provider.request(target) >- subscribeNext { (response) -> Void in
                            receivedResponse = NSJSONSerialization.JSONObjectWithData(response.data, options: nil, error: nil) as? NSDictionary
                        }
                        
                        let sampleData = target.sampleData as NSData
                        let sampleResponse: NSDictionary = NSJSONSerialization.JSONObjectWithData(sampleData, options: nil, error: nil) as! NSDictionary
                        expect(receivedResponse).toNot(beNil())
                    }
                    
                    it("returns identical signals for inflight requests") {
                        let target: Github = .Zen

                        var response: MoyaResponse!

                        let outerSignal = provider.request(target)
                        outerSignal >- subscribeNext { (response) -> Void in
                            expect(provider.inflightRequests.count).to(equal(1))

                            let innerSignal = provider.request(target)
                            innerSignal >- subscribeNext { (object) -> Void in
                                expect(provider.inflightRequests.count).to(equal(1))
                            }
                        }

                        expect(provider.inflightRequests.count).to(equal(0))
                    }
                })
                
                describe("a subsclassed reactive provider that tracks cancellation with delayed stubs") {
                    struct TestCancellable: Cancellable {
                        static var cancelled = false

                        func cancel() {
                            TestCancellable.cancelled = true
                        }
                    }

                    class TestProvider<T: MoyaTarget>: ReactiveCocoaMoyaProvider<T> {
                        override init(endpointClosure: MoyaEndpointsClosure = MoyaProvider.DefaultEndpointMapping, endpointResolver: MoyaEndpointResolution = MoyaProvider.DefaultEnpointResolution, stubBehavior: MoyaStubbedBehavior = MoyaProvider.NoStubbingBehavior, networkActivityClosure: Moya.NetworkActivityClosure? = nil) {
                            super.init(endpointClosure: endpointClosure, endpointResolver: endpointResolver, stubBehavior: stubBehavior, networkActivityClosure: networkActivityClosure)
                        }

                        override func request(token: T, completion: MoyaCompletion) -> Cancellable {
                            return TestCancellable()
                        }
                    }

                    var provider: ReactiveCocoaMoyaProvider<Github>!
                    beforeEach {
                        TestCancellable.cancelled = false
                        
                        provider = TestProvider<Github>(stubBehavior: MoyaProvider.DelayedStubbingBehaviour(1))
                    }
                    
                    it("cancels network request when subscription is cancelled") {
                        var called = false
                        let target: Github = .Zen

                        let disposable = provider.request(target).subscribeCompleted { () -> Void in
                            // Should never be executed
                            fail()
                        }
                        disposable.dispose()

                        expect(TestCancellable.cancelled).to( beTrue() )
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
                
                describe("a reactive provider", { () -> () in
                    var provider: ReactiveCocoaMoyaProvider<Github>!
                    beforeEach {
                        provider = ReactiveCocoaMoyaProvider<Github>(endpointClosure: failureEndpointClosure, stubBehavior: MoyaProvider.ImmediateStubbingBehaviour)
                    }
                    
                    it("returns stubbed data for zen request") {
                        var errored = false
                        
                        let target: Github = .Zen
                        provider.request(target).subscribeError { (error) -> Void in
                            errored = true
                        }
                        
                        expect(errored).to(beTruthy())
                    }
                    
                    it("returns correct data for user profile request") {
                        var errored = false
                        
                        let target: Github = .UserProfile("ashfurrow")
                        provider.request(target).subscribeError { (error) -> Void in
                            errored = true
                        }
                        
                        expect(errored).to(beTruthy())
                    }
                })

                describe("a failing reactive provider") {
                    var provider: ReactiveCocoaMoyaProvider<Github>!
                    beforeEach {
                        provider = ReactiveCocoaMoyaProvider<Github>(endpointClosure: failureEndpointClosure, stubBehavior: MoyaProvider.ImmediateStubbingBehaviour)
                    }

                    it("returns the HTTP status code as the error code") {
                        var code: Int?

                        provider.request(.Zen).subscribeError { (error) -> Void in
                            code = error.code
                        }
                        
                        expect(code).toNot(beNil())
                        expect(code).to(equal(401))
                    }
                }
            }
        }
    }
}
