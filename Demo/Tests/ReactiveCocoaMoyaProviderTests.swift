import Quick
import Nimble
import ReactiveCocoa
import Moya
import Alamofire

class ReactiveCocoaMoyaProviderSpec: QuickSpec {
    override func spec() {
        var provider: ReactiveCocoaMoyaProvider<GitHub>!
        beforeEach {
            provider = ReactiveCocoaMoyaProvider<GitHub>(stubClosure: MoyaProvider.ImmediatelyStub)
        }

        describe("failing") {
            var provider: ReactiveCocoaMoyaProvider<GitHub>!
            beforeEach {
                provider = ReactiveCocoaMoyaProvider<GitHub>(endpointClosure: failureEndpointClosure, stubClosure: MoyaProvider.ImmediatelyStub)
            }
            
            it("returns the correct error message") {
                var receivedError: Moya.Error?
                
                waitUntil { done in
                    provider.request(.Zen).startWithFailed { (error) -> Void in
                        receivedError = error
                        done()
                    }
                }
                
                switch receivedError {
                case .Some(.Underlying(let error)):
                    expect(error.localizedDescription) == "Houston, we have a problem"
                default:
                    fail("expected an Underlying error that Houston has a problem")
                }
            }
            
            it("returns an error") {
                var errored = false
                
                let target: GitHub = .Zen
                provider.request(target).startWithFailed { (error) -> Void in
                    errored = true
                }
                
                expect(errored).to(beTruthy())
            }
        }

        describe("a subsclassed reactive provider that tracks cancellation with delayed stubs") {
            struct TestCancellable: Cancellable {
                static var cancelled = false
                var cancelled: Bool { return TestCancellable.cancelled }

                func cancel() {
                    TestCancellable.cancelled = true
                }
            }

            class TestProvider<Target: TargetType>: ReactiveCocoaMoyaProvider<Target> {
                init(endpointClosure: EndpointClosure = MoyaProvider.DefaultEndpointMapping,
                    requestClosure: RequestClosure = MoyaProvider.DefaultRequestMapping,
                    stubClosure: StubClosure = MoyaProvider.NeverStub,
                    manager: Manager = Alamofire.Manager.sharedInstance,
                    plugins: [PluginType] = []) {

                        super.init(endpointClosure: endpointClosure, requestClosure: requestClosure, stubClosure: stubClosure, manager: manager, plugins: plugins)
                }

                override func request(token: Target, completion: Moya.Completion) -> Cancellable {
                    return TestCancellable()
                }
            }

            var provider: ReactiveCocoaMoyaProvider<GitHub>!
            beforeEach {
                TestCancellable.cancelled = false

                provider = TestProvider<GitHub>(stubClosure: MoyaProvider.DelayedStub(1))
            }

            it("cancels network request when subscription is cancelled") {
                let target: GitHub = .Zen

                let disposable = provider.request(target).startWithCompleted { () -> Void in
                    // Should never be executed
                    fail()
                }
                disposable.dispose()

                expect(TestCancellable.cancelled).to( beTrue() )
            }
        }

        describe("provider with SignalProducer") {

            it("returns a Response object") {
                var called = false
                
                provider.request(.Zen).startWithNext { (object) -> Void in
                    called = true
                }
                
                expect(called).to(beTruthy())
            }

            it("returns stubbed data for zen request") {
                var message: String?
                
                let target: GitHub = .Zen
                provider.request(target).startWithNext { (response) -> Void in
                    message = NSString(data: response.data, encoding: NSUTF8StringEncoding) as? String
                }
                
                let sampleString = NSString(data: (target.sampleData as NSData), encoding: NSUTF8StringEncoding)
                expect(message).to(equal(sampleString))
            }
            
            it("returns correct data for user profile request") {
                var receivedResponse: NSDictionary?
                
                let target: GitHub = .UserProfile("ashfurrow")
                provider.request(target).startWithNext { (response) -> Void in
                    receivedResponse = try! NSJSONSerialization.JSONObjectWithData(response.data, options: []) as? NSDictionary
                }
                
                let sampleData = target.sampleData as NSData
                let sampleResponse: NSDictionary = try! NSJSONSerialization.JSONObjectWithData(sampleData, options: []) as! NSDictionary
                expect(receivedResponse).toNot(beNil())
                expect(receivedResponse) == sampleResponse
            }
            
            describe("a subsclassed reactive provider that tracks cancellation with delayed stubs") {
                struct TestCancellable: Cancellable {
                    static var cancelled = false
                    var cancelled: Bool { return TestCancellable.cancelled }
                    
                    func cancel() {
                        TestCancellable.cancelled = true
                    }
                }
                
                class TestProvider<Target: TargetType>: ReactiveCocoaMoyaProvider<Target> {
                    init(endpointClosure: EndpointClosure = MoyaProvider.DefaultEndpointMapping,
                        requestClosure: RequestClosure = MoyaProvider.DefaultRequestMapping,
                        stubClosure: StubClosure = MoyaProvider.NeverStub,
                        manager: Manager = Alamofire.Manager.sharedInstance,
                        plugins: [PluginType] = []) {

                            super.init(endpointClosure: endpointClosure, requestClosure: requestClosure, stubClosure: stubClosure, manager: manager, plugins: plugins)
                    }
                    
                    override func request(token: Target, completion: Moya.Completion) -> Cancellable {
                        return TestCancellable()
                    }
                }
                
                var provider: ReactiveCocoaMoyaProvider<GitHub>!
                beforeEach {
                    TestCancellable.cancelled = false
                    
                    provider = TestProvider<GitHub>(stubClosure: MoyaProvider.DelayedStub(1))
                }
                
                it("cancels network request when subscription is cancelled") {
                    let target: GitHub = .Zen
                    
                    let disposable = provider.request(target).startWithCompleted { () -> Void in
                        // Should never be executed
                        fail()
                    }
                    disposable.dispose()
                    
                    expect(TestCancellable.cancelled).to( beTrue() )
                }
            }
        }
        describe("provider with a TestScheduler") {
            var testScheduler: TestScheduler! = nil
            var response: Moya.Response? = nil
            beforeEach {
                testScheduler = TestScheduler()
                provider = ReactiveCocoaMoyaProvider<GitHub>(stubClosure: MoyaProvider.ImmediatelyStub, stubScheduler: testScheduler)
                provider.request(.Zen).startWithNext { next in
                    response = next
                }
            }
            afterEach {
                response = nil
            }

            it("sends the stub when the test scheduler is advanced") {
                testScheduler.run()
                expect(response).toNot(beNil())
            }
            it("does not send the stub when the test scheduler is not advanced") {
                expect(response).to(beNil())
            }
        }
        
        describe("a reactive provider") {
            var provider: ReactiveCocoaMoyaProvider<GitHub>!
            beforeEach {
                provider = ReactiveCocoaMoyaProvider<GitHub>(trackInflights: true)
            }

            it("returns identical signalproducers for inflight requests") {
                let target: GitHub = .Zen
                let signalProducer1:SignalProducer<Moya.Response, Moya.Error> = provider.request(target)
                let signalProducer2:SignalProducer<Moya.Response, Moya.Error> = provider.request(target)

                expect(provider.inflightRequests.keys.count).to(equal(0))

                var receivedResponse: Moya.Response!

                signalProducer1.startWithNext { (response) -> Void in
                    receivedResponse = response
                    expect(provider.inflightRequests.count).to(equal(1))
                }

                signalProducer2.startWithNext { (response) -> Void in
                    expect(receivedResponse).toNot(beNil())
                    expect(receivedResponse).to(beIndenticalToResponse(response))
                    expect(provider.inflightRequests.count).to(equal(1))
                }


                // Allow for network request to complete
                expect(provider.inflightRequests.count).toEventually( equal(0))
                
            }
        }

    }
}
