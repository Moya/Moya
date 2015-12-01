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
        
        describe("provider with RACSignal") {
            
            it("returns a Response object") {
                var called = false
                
                provider.request(.Zen).subscribeNext { (object) -> Void in
                    if let _ = object as? Moya.Response {
                        called = true
                    }
                }
                
                expect(called).to(beTruthy())
            }
            
            it("returns stubbed data for zen request") {
                var message: String?
                
                let target: GitHub = .Zen
                provider.request(target).subscribeNext { (object) -> Void in
                    if let response = object as? Moya.Response {
                        message = NSString(data: response.data, encoding: NSUTF8StringEncoding) as? String
                    }
                }
                
                _ = target.sampleData as NSData
                expect(message).toNot(beNil())
            }
            
            it("returns correct data for user profile request") {
                var receivedResponse: NSDictionary?
                
                let target: GitHub = .UserProfile("ashfurrow")
                provider.request(target).subscribeNext { (object) -> Void in
                    if let response = object as? Moya.Response {
                        receivedResponse = try! NSJSONSerialization.JSONObjectWithData(response.data, options: []) as? NSDictionary
                    }
                }
                
                let sampleData = target.sampleData as NSData
                let sampleResponse = try! NSJSONSerialization.JSONObjectWithData(sampleData, options: []) as! NSDictionary
                
                expect(receivedResponse) == sampleResponse
            }
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
                case .Some(.Underlying(let error as NSError)):
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
    }
}
