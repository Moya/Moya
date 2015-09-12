import Quick
import Moya
import Nimble
import ReactiveCocoa
import RxSwift
import Alamofire

class MoyaProviderSpec: QuickSpec {
    override func spec() {
        describe("valid endpoints") {
            describe("with stubbed responses") {
                describe("a provider", {
                    var provider: MoyaProvider<GitHub>!
                    beforeEach {
                        provider = MoyaProvider<GitHub>(stubBehavior: MoyaProvider.ImmediateStubbingBehaviour)
                    }
                    
                    it("returns stubbed data for zen request") {
                        var message: String?
                        
                        let target: GitHub = .Zen
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
                        
                        let target: GitHub = .UserProfile("ashfurrow")
                        provider.request(target) { (data, statusCode, response, error) in
                            if let data = data {
                                message = NSString(data: data, encoding: NSUTF8StringEncoding) as? String
                            }
                        }
                        
                        let sampleData = target.sampleData as NSData
                        expect(message).to(equal(NSString(data: sampleData, encoding: NSUTF8StringEncoding)))
                    }
                    
                    it("returns equivalent Endpoint instances for the same target") {
                        let target: GitHub = .Zen
                        
                        let endpoint1 = provider.endpoint(target)
                        let endpoint2 = provider.endpoint(target)
                        expect(endpoint1).to(equal(endpoint2))
                    }
                    
                    it("returns a cancellable object when a request is made") {
                        let target: GitHub = .UserProfile("ashfurrow")
                        
                        let cancellable: Cancellable = provider.request(target) { (_, _, _, _) in }
                        
                        expect(cancellable).toNot(beNil())

                    }

                    it("uses the Alamofire.Manager.sharedInstance by default") {
                        expect(provider.manager).to(beIdenticalTo(Alamofire.Manager.sharedInstance))
                    }

                    it("accepts a custom Alamofire.Manager") {
                        let manager = Manager()
                        let provider = MoyaProvider<GitHub>(manager: manager)

                        expect(provider.manager).to(beIdenticalTo(manager))
                    }
                })

                it("notifies at the beginning of network requests") {
                    var called = false
                    var provider = MoyaProvider<GitHub>(stubBehavior: MoyaProvider.ImmediateStubbingBehaviour, networkActivityClosure: { (change) -> () in
                        if change == .Began {
                            called = true
                        }
                    })

                    let target: GitHub = .Zen
                    provider.request(target) { (data, statusCode, response, error) in }

                    expect(called) == true
                }

                it("notifies at the end of network requests") {
                    var called = false
                    var provider = MoyaProvider<GitHub>(stubBehavior: MoyaProvider.ImmediateStubbingBehaviour, networkActivityClosure: { (change) -> () in
                        if change == .Ended {
                            called = true
                        }
                    })

                    let target: GitHub = .Zen
                    provider.request(target) { (data, statusCode, response, error) in }
                    
                    expect(called) == true
                }

                describe("a provider with lazy data", { () -> () in
                    var provider: MoyaProvider<GitHub>!
                    beforeEach {
                        provider = MoyaProvider<GitHub>(endpointClosure: lazyEndpointClosure, stubBehavior: MoyaProvider.ImmediateStubbingBehaviour)
                    }

                    it("returns stubbed data for zen request") {
                        var message: String?

                        let target: GitHub = .Zen
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
                    let provider = MoyaProvider<GitHub>(stubBehavior: MoyaProvider.DelayedStubbingBehaviour(2))

                    let startDate = NSDate()
                    var endDate: NSDate?
                    let target: GitHub = .Zen
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
                    var provider: MoyaProvider<GitHub>!
                    var executed = false
                    let newSampleResponse = "New Sample Response"
                    
                    beforeEach {
                        executed = false
                        let endpointResolution = { (endpoint: Endpoint<GitHub>) -> (NSURLRequest) in
                            executed = true
                            return endpoint.urlRequest
                        }
                        provider = MoyaProvider<GitHub>(endpointResolver: endpointResolution, stubBehavior: MoyaProvider.ImmediateStubbingBehaviour)
                    }
                    
                    it("executes the endpoint resolver") {
                        let target: GitHub = .Zen
                        provider.request(target, completion: { (data, statusCode, response, error) in })
                        
                        let sampleData = target.sampleData as NSData
                        expect(executed).to(beTruthy())
                    }
                }
                
                describe("a reactive provider", { () -> () in
                    var provider: ReactiveCocoaMoyaProvider<GitHub>!
                    beforeEach {
                        provider = ReactiveCocoaMoyaProvider<GitHub>(stubBehavior: MoyaProvider.ImmediateStubbingBehaviour)
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
                        
                        let target: GitHub = .Zen
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
                        
                        let target: GitHub = .UserProfile("ashfurrow")
                        provider.request(target).subscribeNext { (object) -> Void in
                            if let response = object as? MoyaResponse {
                                receivedResponse = try! NSJSONSerialization.JSONObjectWithData(response.data, options: []) as? NSDictionary
                            }
                        }
                        
                        let sampleData = target.sampleData as NSData
                        let sampleResponse = try! NSJSONSerialization.JSONObjectWithData(sampleData, options: []) as! NSDictionary
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
                        outerSignal.subscribeNext { (object) -> Void in
                            response = object as? MoyaResponse
                            expect(provider.inflightRequests.count).to(equal(1))
                            
                            // Create a new signal and force subscription, so that the inflightRequests dictionary is accessed.
                            let innerSignal = provider.request(target)
                            innerSignal.subscribeNext { (object) -> Void in
                                // nop
                            }
                            expect(provider.inflightRequests.count).to(equal(1))
                        }
                        
                        expect(provider.inflightRequests.count).to(equal(0))
                    }
                })

                describe("a RxSwift provider", { () -> () in
                    var provider: RxMoyaProvider<GitHub>!
                    
                    beforeEach {
                        provider = RxMoyaProvider(stubBehavior: MoyaProvider.ImmediateStubbingBehaviour)
                    }
                    
                    it("returns a MoyaResponse object") {
                        var called = false
                        
                        provider.request(.Zen).subscribeNext { (object) -> Void in
                            called = true
                        }
                        
                        expect(called).to(beTruthy())
                    }
                    
                    it("returns stubbed data for zen request") {
                        var message: String?
                        
                        let target: GitHub = .Zen
                        provider.request(target).subscribeNext { (response) -> Void in
                            message = NSString(data: response.data, encoding: NSUTF8StringEncoding) as? String
                        }
                        
                        let sampleString = NSString(data: (target.sampleData as NSData), encoding: NSUTF8StringEncoding)
                        expect(message).to(equal(sampleString))
                    }

                    it("returns correct data for user profile request") {
                        var receivedResponse: NSDictionary?
                        
                        let target: GitHub = .UserProfile("ashfurrow")
                        provider.request(target).subscribeNext { (response) -> Void in
                            receivedResponse = try! NSJSONSerialization.JSONObjectWithData(response.data, options: []) as? NSDictionary
                        }
                        
                        let sampleData = target.sampleData as NSData
                        let sampleResponse: NSDictionary = try! NSJSONSerialization.JSONObjectWithData(sampleData, options: []) as! NSDictionary
                        expect(receivedResponse).toNot(beNil())
                    }
                    
                    it("returns identical observables for inflight requests") {
                        let target: GitHub = .Zen

                        var response: MoyaResponse!

                        let parallelCount = 10
                        let observables = Array(0..<parallelCount).map { _ in provider.request(target) }
                        var completions = Array(0..<parallelCount).map { _ in false }
                        let queue = dispatch_queue_create("testing", DISPATCH_QUEUE_CONCURRENT)
                        dispatch_apply(observables.count, queue, { idx in
                            let i = idx
                            observables[i].subscribeNext { _ -> Void in
                                if i == 5 { // We only need to check it once.
                                    expect(provider.inflightRequests.count).to(equal(1))
                                }
                                completions[i] = true
                            }
                        })
                        
                        func allTrue(cs: [Bool]) -> Bool {
                            return cs.reduce(true) { (a,b) -> Bool in a && b }
                        }
                        
                        expect(allTrue(completions)).toEventually(beTrue())
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
                        override init(endpointClosure: MoyaEndpointsClosure = MoyaProvider.DefaultEndpointMapping, endpointResolver: MoyaEndpointResolution = MoyaProvider.DefaultEndpointResolution, stubBehavior: MoyaStubbedBehavior = MoyaProvider.NoStubbingBehavior, networkActivityClosure: Moya.NetworkActivityClosure? = nil, manager: Manager = Alamofire.Manager.sharedInstance) {
                            super.init(endpointClosure: endpointClosure, endpointResolver: endpointResolver, stubBehavior: stubBehavior, networkActivityClosure: networkActivityClosure, manager: manager)
                        }

                        override func request(token: T, completion: MoyaCompletion) -> Cancellable {
                            return TestCancellable()
                        }
                    }

                    var provider: ReactiveCocoaMoyaProvider<GitHub>!
                    beforeEach {
                        TestCancellable.cancelled = false
                        
                        provider = TestProvider<GitHub>(stubBehavior: MoyaProvider.DelayedStubbingBehaviour(1))
                    }
                    
                    it("cancels network request when subscription is cancelled") {
                        var called = false
                        let target: GitHub = .Zen

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
                    var provider: MoyaProvider<GitHub>!
                    beforeEach {
                        provider = MoyaProvider(endpointClosure: failureEndpointClosure, stubBehavior: MoyaProvider.ImmediateStubbingBehaviour)
                    }
                    
                    it("returns stubbed data for zen request") {
                        var errored = false
                        
                        let target: GitHub = .Zen
                        provider.request(target) { (object, statusCode, response, error) in
                            if error != nil {
                                errored = true
                            }
                        }
                        
                        let _ = target.sampleData
                        expect(errored).toEventually(beTruthy())
                    }
                    
                    it("returns stubbed data for user profile request") {
                        var errored = false
                        
                        let target: GitHub = .UserProfile("ashfurrow")
                        provider.request(target) { (object, statusCode, response, error) in
                            if error != nil {
                                errored = true
                            }
                        }
                        
                        let _ = target.sampleData
                        expect{errored}.toEventually(beTruthy(), timeout: 1, pollInterval: 0.1)
                    }
                    
                    it("returns stubbed error data when present") {
                        var errorMessage = ""
                        
                        let target: GitHub = .UserProfile("ashfurrow")
                        provider.request(target) { (object, statusCode, response, error) in
                            if let object = object {
                                errorMessage = NSString(data: object, encoding: NSUTF8StringEncoding) as! String
                            }
                        }

                        expect{errorMessage}.toEventually(equal("Houston, we have a problem"), timeout: 1, pollInterval: 0.1)
                    }
                }
                
                describe("a reactive provider", { () -> () in
                    var provider: ReactiveCocoaMoyaProvider<GitHub>!
                    beforeEach {
                        provider = ReactiveCocoaMoyaProvider<GitHub>(endpointClosure: failureEndpointClosure, stubBehavior: MoyaProvider.ImmediateStubbingBehaviour)
                    }
                    
                    it("returns stubbed data for zen request") {
                        var errored = false
                        
                        let target: GitHub = .Zen
                        provider.request(target).subscribeError { (error) -> Void in
                            errored = true
                        }
                        
                        expect(errored).to(beTruthy())
                    }
                    
                    it("returns correct data for user profile request") {
                        var errored = false
                        
                        let target: GitHub = .UserProfile("ashfurrow")
                        provider.request(target).subscribeError { (error) -> Void in
                            errored = true
                        }
                        
                        expect(errored).to(beTruthy())
                    }
                })

                describe("a failing reactive provider") {
                    var provider: ReactiveCocoaMoyaProvider<GitHub>!
                    beforeEach {
                        provider = ReactiveCocoaMoyaProvider<GitHub>(endpointClosure: failureEndpointClosure, stubBehavior: MoyaProvider.ImmediateStubbingBehaviour)
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
