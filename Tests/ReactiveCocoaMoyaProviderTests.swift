import Quick
import Nimble
import ReactiveSwift
import OHHTTPStubs
@testable
import Moya
import Alamofire

#if !COCOAPODS
import ReactiveMoya
#endif

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
                    provider.request(token: .zen).startWithFailed { (error) -> Void in
                        receivedError = error
                        done()
                    }
                }
                
                switch receivedError {
                case .some(.underlying(let error)):
                    expect(error.localizedDescription) == "Houston, we have a problem"
                default:
                    fail("expected an Underlying error that Houston has a problem")
                }
            }
            
            it("returns an error") {
                var errored = false
                
                let target: GitHub = .zen
                provider.request(token: target).startWithFailed { (error) -> Void in
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
                init(endpointClosure: @escaping EndpointClosure = MoyaProvider.DefaultEndpointMapping,
                    requestClosure: @escaping RequestClosure = MoyaProvider.DefaultRequestMapping,
                    stubClosure: @escaping StubClosure = MoyaProvider.NeverStub,
                    manager: Manager = MoyaProvider<Target>.DefaultAlamofireManager(),
                    plugins: [PluginType] = []) {

                        super.init(endpointClosure: endpointClosure, requestClosure: requestClosure, stubClosure: stubClosure, manager: manager, plugins: plugins)
                }

                override func request(_ target: Target, completion: @escaping Moya.Completion) -> Cancellable {
                    return TestCancellable()
                }
            }

            var provider: ReactiveCocoaMoyaProvider<GitHub>!
            beforeEach {
                TestCancellable.cancelled = false

                provider = TestProvider<GitHub>(stubClosure: MoyaProvider.DelayedStub(1))
            }

            it("cancels network request when subscription is cancelled") {
                let target: GitHub = .zen

                let disposable = provider.request(token: target).startWithCompleted { () -> Void in
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
                
                provider.request(token: .zen).startWithResult({ _ in
                    called = true
                })
                
                expect(called).to(beTruthy())
            }

            it("returns stubbed data for zen request") {
                var message: String?
                
                let target: GitHub = .zen
                provider.request(token: target).startWithResult { (result) -> Void in
                    if case .success(let response) = result {
                        message = String(data: response.data, encoding: .utf8)
                    }
                }
                
                let sampleString = String(data: target.sampleData, encoding: .utf8)
                expect(message!).to(equal(sampleString))
            }
            
            it("returns correct data for user profile request") {
                var receivedResponse: NSDictionary?
                
                let target: GitHub = .userProfile("ashfurrow")
                provider.request(token: target).startWithResult { (result) -> Void in
                    if case .success(let response) = result {
                        receivedResponse = try! JSONSerialization.jsonObject(with: response.data, options: []) as? NSDictionary
                    }
                }
                
                let sampleData = target.sampleData as NSData
                let sampleResponse: NSDictionary = try! JSONSerialization.jsonObject(with: sampleData as Data, options: []) as! NSDictionary
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
                    init(endpointClosure: @escaping EndpointClosure = MoyaProvider.DefaultEndpointMapping,
                        requestClosure: @escaping RequestClosure = MoyaProvider.DefaultRequestMapping,
                        stubClosure: @escaping StubClosure = MoyaProvider.NeverStub,
                        manager: Manager = MoyaProvider<Target>.DefaultAlamofireManager(),
                        plugins: [PluginType] = []) {

                            super.init(endpointClosure: endpointClosure, requestClosure: requestClosure, stubClosure: stubClosure, manager: manager, plugins: plugins)
                    }
                    
                    override func request(_ target: Target, completion: @escaping Moya.Completion) -> Cancellable {
                        return TestCancellable()
                    }
                }
                
                var provider: ReactiveCocoaMoyaProvider<GitHub>!
                beforeEach {
                    TestCancellable.cancelled = false
                    
                    provider = TestProvider<GitHub>(stubClosure: MoyaProvider.DelayedStub(1))
                }
                
                it("cancels network request when subscription is cancelled") {
                    let target: GitHub = .zen
                    
                    let disposable = provider.request(token: target).startWithCompleted { () -> Void in
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
                provider.request(token: .zen).startWithResult { result in
                    if case .success(let next) = result {
                        response = next
                    }
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
                OHHTTPStubs.stubRequests(passingTest: {$0.url!.path == "/zen"}) { _ in
                    return OHHTTPStubsResponse(data: GitHub.zen.sampleData, statusCode: 200, headers: nil)
                }
                provider = ReactiveCocoaMoyaProvider<GitHub>(trackInflights: true)
            }

            it("returns identical signalproducers for inflight requests") {
                let target: GitHub = .zen
                let signalProducer1: SignalProducer<Moya.Response, Moya.Error> = provider.request(token: target)
                let signalProducer2: SignalProducer<Moya.Response, Moya.Error> = provider.request(token: target)

                expect(provider.inflightRequests.keys.count).to( equal(0) )

                var receivedResponse: Moya.Response!

                signalProducer1.startWithResult { (result) -> Void in
                    if case .success(let response) = result {
                        receivedResponse = response
                        expect(provider.inflightRequests.count).to( equal(1) )
                    }
                }

                signalProducer2.startWithResult { (result) -> Void in
                    if case .success(let response) = result {
                        expect(receivedResponse).toNot( beNil() )
                        expect(receivedResponse).to( beIdenticalToResponse(response) )
                        expect(provider.inflightRequests.count).to( equal(1) )
                    }
                }


                // Allow for network request to complete
                expect(provider.inflightRequests.count).toEventually( equal(0) )
                
            }
        }

    }
}
