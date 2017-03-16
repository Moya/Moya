import Quick
import Nimble
import ReactiveSwift
import OHHTTPStubs
import Alamofire

@testable import Moya
@testable import ReactiveMoya

class ReactiveSwiftMoyaProviderSpec: QuickSpec {
    override func spec() {
        var provider: ReactiveSwiftMoyaProvider<GitHub>!
        beforeEach {
            provider = ReactiveSwiftMoyaProvider<GitHub>(stubClosure: MoyaProvider.immediatelyStub)
        }

        describe("failing") {
            var provider: ReactiveSwiftMoyaProvider<GitHub>!
            beforeEach {
                provider = ReactiveSwiftMoyaProvider<GitHub>(endpointClosure: failureEndpointClosure, stubClosure: MoyaProvider.immediatelyStub)
            }
            
            it("returns the correct error message") {
                var receivedError: MoyaError?
                
                waitUntil { done in
                    provider.request(.zen).startWithFailed { error in
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
                provider.request(target).startWithFailed { error in
                    errored = true
                }
                
                expect(errored).to(beTruthy())
            }
        }

        describe("a subsclassed reactive provider that tracks cancellation with delayed stubs") {
            struct TestCancellable: Cancellable {
                static var isCancelled = false
                var isCancelled: Bool { return TestCancellable.isCancelled }

                func cancel() {
                    TestCancellable.isCancelled = true
                }
            }

            class TestProvider<Target: TargetType>: ReactiveSwiftMoyaProvider<Target> {
                init(endpointClosure: @escaping EndpointClosure = MoyaProvider.defaultEndpointMapping,
                    requestClosure: @escaping RequestClosure = MoyaProvider.defaultRequestMapping,
                    stubClosure: @escaping StubClosure = MoyaProvider.neverStub,
                    manager: Manager = MoyaProvider<Target>.defaultAlamofireManager(),
                    plugins: [PluginType] = []) {

                        super.init(endpointClosure: endpointClosure, requestClosure: requestClosure, stubClosure: stubClosure, manager: manager, plugins: plugins)
                }

                override func request(_ target: Target, completion: @escaping Moya.Completion) -> Cancellable {
                    return TestCancellable()
                }
            }

            var provider: ReactiveSwiftMoyaProvider<GitHub>!
            beforeEach {
                TestCancellable.isCancelled = false

                provider = TestProvider<GitHub>(stubClosure: MoyaProvider.delayedStub(1))
            }

            it("cancels network request when subscription is cancelled") {
                let target: GitHub = .zen

                let disposable = provider.request(target).startWithCompleted {
                    // Should never be executed
                    fail()
                }
                disposable.dispose()

                expect(TestCancellable.isCancelled).to( beTrue() )
            }
        }

        describe("provider with SignalProducer") {

            it("returns a Response object") {
                var called = false
                
                provider.request(.zen).startWithResult { _ in
                    called = true
                }
                
                expect(called).to(beTruthy())
            }

            it("returns stubbed data for zen request") {
                var message: String?
                
                let target: GitHub = .zen
                provider.request(target).startWithResult { result in
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
                provider.request(target).startWithResult { result in
                    if case .success(let response) = result {
                        receivedResponse = try! JSONSerialization.jsonObject(with: response.data, options: []) as? NSDictionary
                    }
                }
                
                let sampleData = target.sampleData
                let sampleResponse = try! JSONSerialization.jsonObject(with: sampleData, options: []) as! NSDictionary
                expect(receivedResponse).toNot(beNil())
                expect(receivedResponse) == sampleResponse
            }
            
            describe("a subsclassed reactive provider that tracks cancellation with delayed stubs") {
                struct TestCancellable: Cancellable {
                    static var isCancelled = false
                    var isCancelled: Bool { return TestCancellable.isCancelled }
                    
                    func cancel() {
                        TestCancellable.isCancelled = true
                    }
                }
                
                class TestProvider<Target: TargetType>: ReactiveSwiftMoyaProvider<Target> {
                    init(endpointClosure: @escaping EndpointClosure = MoyaProvider.defaultEndpointMapping,
                        requestClosure: @escaping RequestClosure = MoyaProvider.defaultRequestMapping,
                        stubClosure: @escaping StubClosure = MoyaProvider.neverStub,
                        manager: Manager = MoyaProvider<Target>.defaultAlamofireManager(),
                        plugins: [PluginType] = []) {

                            super.init(endpointClosure: endpointClosure, requestClosure: requestClosure, stubClosure: stubClosure, manager: manager, plugins: plugins)
                    }
                    
                    override func request(_ target: Target, completion: @escaping Moya.Completion) -> Cancellable {
                        return TestCancellable()
                    }
                }
                
                var provider: ReactiveSwiftMoyaProvider<GitHub>!
                beforeEach {
                    TestCancellable.isCancelled = false
                    
                    provider = TestProvider<GitHub>(stubClosure: MoyaProvider.delayedStub(1))
                }
                
                it("cancels network request when subscription is cancelled") {
                    let target: GitHub = .zen
                    
                    let disposable = provider.request(target).startWithCompleted {
                        // Should never be executed
                        fail()
                    }
                    disposable.dispose()
                    
                    expect(TestCancellable.isCancelled).to( beTrue() )
                }
            }
        }
        describe("provider with a TestScheduler") {
            var testScheduler: TestScheduler! = nil
            var response: Moya.Response? = nil
            beforeEach {
                testScheduler = TestScheduler()
                provider = ReactiveSwiftMoyaProvider<GitHub>(stubClosure: MoyaProvider.immediatelyStub, stubScheduler: testScheduler)
                provider.request(.zen).startWithResult { result in
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
            var provider: ReactiveSwiftMoyaProvider<GitHub>!
            beforeEach {
                OHHTTPStubs.stubRequests(passingTest: {$0.url!.path == "/zen"}) { _ in
                    return OHHTTPStubsResponse(data: GitHub.zen.sampleData, statusCode: 200, headers: nil)
                }
                provider = ReactiveSwiftMoyaProvider<GitHub>(trackInflights: true)
            }

            it("returns identical signalproducers for inflight requests") {
                let target: GitHub = .zen
                let signalProducer1: SignalProducer<Moya.Response, MoyaError> = provider.request(target)
                let signalProducer2: SignalProducer<Moya.Response, MoyaError> = provider.request(target)

                expect(provider.inflightRequests.keys.count).to( equal(0) )

                var receivedResponse: Moya.Response!

                signalProducer1.startWithResult { result in
                    if case .success(let response) = result {
                        receivedResponse = response
                        expect(provider.inflightRequests.count).to( equal(1) )
                    }
                }

                signalProducer2.startWithResult { result in
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
