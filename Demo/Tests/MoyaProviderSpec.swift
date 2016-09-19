import Quick
import Nimble
import Alamofire
import Foundation
import OHHTTPStubs
@testable import Moya

class MoyaProviderSpec: QuickSpec {
    override func spec() {
        var provider: MoyaProvider<GitHub>!
        beforeEach {
            provider = MoyaProvider<GitHub>(stubClosure: MoyaProvider.ImmediatelyStub)
        }
        
        it("returns stubbed data for zen request") {
            var message: String?
            
            let target: GitHub = .zen
            _ = provider.request(target) { result in
                if case let .success(response) = result {
                    message = String(data: response.data, encoding: .utf8)
                }
            }
            
            let sampleData = target.sampleData
            expect(message).to(equal(String(data: sampleData, encoding: .utf8)))
        }

        it("returns response with request for stubbed zen request") {
            var request: URLRequest?

            let target: GitHub = .zen
            provider.request(target) { result in
                if case let .success(response) = result {
                    request = response.request
                }
            }

            expect(request).toNot(beNil())
        }

        it("returns stubbed data for user profile request") {
            var message: String?
            
            let target: GitHub = .userProfile("ashfurrow")
            _ = provider.request(target) { result in
                if case let .success(response) = result {
                    message = String(data: response.data, encoding: .utf8)
                }
            }
            
            let sampleData = target.sampleData
            expect(message).to(equal(String(data: sampleData, encoding: .utf8)))
        }
        
        it("returns equivalent Endpoint instances for the same target") {
            let target: GitHub = .zen
            
            let endpoint1 = provider.endpoint(target)
            let endpoint2 = provider.endpoint(target)
            expect(endpoint1.urlRequest).to(equal(endpoint2.urlRequest))
        }

        it("returns a cancellable object when a request is made") {
            let target: GitHub = .userProfile("ashfurrow")
            let cancellable: Cancellable = provider.request(target) { _ in  }

            expect(cancellable).toNot(beNil())
        }

        it("uses a custom manager by default, startRequestsImmediately should be false") {
            expect(provider.manager).toNot(beNil())
            expect(provider.manager.startRequestsImmediately) == false
        }

        it("credential closure returns nil") {
            var called = false
            let plugin = CredentialsPlugin { (target) -> URLCredential? in
                called = true
                return nil
            }
            
            let provider = MoyaProvider<HTTPBin>(stubClosure: MoyaProvider.ImmediatelyStub, plugins: [plugin])
            let target: HTTPBin = .basicAuth
            _ = provider.request(target) { _ in  }
            
            expect(called) == true
        }
        
        it("credential closure returns valid username and password") {
            var called = false
            let plugin = CredentialsPlugin { (target) -> URLCredential? in
                called = true
                return URLCredential(user: "user", password: "passwd", persistence: .none)
            }
            
            let provider = MoyaProvider<HTTPBin>(stubClosure: MoyaProvider.ImmediatelyStub, plugins: [plugin])
            let target: HTTPBin = .basicAuth
            _ = provider.request(target) { _ in  }
            
            expect(called) == true
        }
        
        it("accepts a custom Alamofire.Manager") {
            let manager = Manager()
            let provider = MoyaProvider<GitHub>(manager: manager)
            
            expect(provider.manager).to(beIdenticalTo(manager))
        }
        
        it("notifies at the beginning of network requests") {
            var called = false
            let plugin = NetworkActivityPlugin { (change) -> () in
                if change == .began {
                    called = true
                }
            }
            
            let provider = MoyaProvider<GitHub>(stubClosure: MoyaProvider.ImmediatelyStub, plugins: [plugin])
            let target: GitHub = .zen
            _ = provider.request(target) { _ in  }
            
            expect(called) == true
        }
        
        it("notifies at the end of network requests") {
            var called = false
            let plugin = NetworkActivityPlugin { (change) -> () in
                if change == .ended {
                    called = true
                }
            }
            
            let provider = MoyaProvider<GitHub>(stubClosure: MoyaProvider.ImmediatelyStub, plugins: [plugin])
            let target: GitHub = .zen
            _ = provider.request(target) { _ in  }
            
            expect(called) == true
        }

        describe("a provider with delayed stubs") {
            var provider: MoyaProvider<GitHub>!
            var plugin: TestingPlugin!
            let delay: TimeInterval = 0.5

            beforeEach {
                plugin = TestingPlugin()
                provider = MoyaProvider<GitHub>(stubClosure: MoyaProvider.DelayedStub(delay), plugins: [plugin])
            }

            it("delays execution") {
                let startDate = Date()
                var endDate: NSDate?
                let target: GitHub = .zen
                waitUntil { done in
                    _ = provider.request(target) { _ in
                        endDate = NSDate()
                        done()
                    }
                    return
                }

                expect(endDate?.timeIntervalSince(startDate)) >= delay
            }

            it("returns an error when request is cancelled") {
                var receivedError: Swift.Error?

                waitUntil { done in
                    let target: GitHub = .userProfile("ashfurrow")
                    let token = provider.request(target) { result in
                        if case let .failure(error) = result {
                            receivedError = error
                        }
                        done()
                    }
                    token.cancel()
                }
                
                expect(receivedError).toNot( beNil() )
            }

            it("notifies plugins when request is cancelled") {
                var receivedError: Swift.Error?

                waitUntil { done in
                    let target: GitHub = .userProfile("ashfurrow")
                    let token = provider.request(target) { _ in
                        done()
                    }
                    token.cancel()
                }

                if let result = plugin.result,
                    case let .failure(error) = result
                {
                    receivedError = error
                }
                expect(receivedError).toNot( beNil() )
            }

            it("returns success when request is not cancelled") {
                var receivedError: Swift.Error?

                waitUntil { done in
                    let target: GitHub = .userProfile("ashfurrow")
                    let token = provider.request(target) { result in
                        if case let .failure(error) = result {
                            receivedError = error
                        }
                        done()
                    }
                }

                expect(receivedError).to( beNil() )
            }
        }

        describe("a provider with a delayed endpoint resolver") {
            let beforeRequest: TimeInterval = 0.05
            let requestTime: TimeInterval = 0.1
            let beforeResponse: TimeInterval = 0.15
            let responseTime: TimeInterval = 0.2
            let afterResponse: TimeInterval = 0.3
            var provider: MoyaProvider<GitHub>!

            func delay(_ delay: TimeInterval, block: @escaping () -> ()) {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: block)
            }

            beforeEach {
                let endpointResolution: MoyaProvider<GitHub>.RequestClosure = { endpoint, done in
                    delay(requestTime) {
                        done(.success(endpoint.urlRequest))
                    }
                }
                provider = MoyaProvider<GitHub>(requestClosure: endpointResolution, stubClosure: MoyaProvider.DelayedStub(responseTime))
            }

            it("returns success eventually") {
                var receivedError: Swift.Error?

                waitUntil { done in
                    let target: GitHub = .userProfile("ashfurrow")
                    _ = provider.request(target) { result in
                        if case let .failure(error) = result {
                            receivedError = error
                        }
                        done()
                    }
                }

                expect(receivedError).to( beNil() )
            }

            it("calls completion if cancelled immediately") {
                var receivedError: Swift.Error?
                var calledCompletion = false

                waitUntil { done in
                    let target: GitHub = .userProfile("ashfurrow")
                    let token = provider.request(target) { result in
                        calledCompletion = true
                        if case let .failure(error) = result {
                            receivedError = error
                        }
                    }
                    token.cancel()
                    delay(afterResponse) {
                        done()
                    }
                }

                expect(receivedError).toNot( beNil() )
                expect(calledCompletion).to( beTrue() )
            }

            it("calls completion if cancelled before request is created") {
                var receivedError: Swift.Error?
                var calledCompletion = false

                waitUntil { done in
                    let target: GitHub = .userProfile("ashfurrow")
                    let token = provider.request(target) { result in
                        calledCompletion = true
                        if case let .failure(error) = result {
                            receivedError = error
                        }
                    }
                    delay(beforeRequest) {
                        token.cancel()
                    }
                    delay(afterResponse) {
                        done()
                    }
                }

                expect(receivedError).toNot( beNil() )
                expect(calledCompletion).to( beTrue() )
            }

            it("receives an error if request is cancelled before response comes back") {
                var receivedError: Swift.Error?

                waitUntil { done in
                    let target: GitHub = .userProfile("ashfurrow")
                    let token = provider.request(target) { result in
                        if case let .failure(error) = result {
                            receivedError = error
                        }
                        done()
                    }
                    delay(beforeResponse) {
                        token.cancel()
                    }
                }

                expect(receivedError).toNot( beNil() )
            }
        }

        describe("a provider with a custom endpoint resolver") {
            var provider: MoyaProvider<GitHub>!
            var executed = false

            beforeEach {
                executed = false
                let endpointResolution: MoyaProvider<GitHub>.RequestClosure = { endpoint, done in
                    executed = true
                    done(.success(endpoint.urlRequest))
                }
                provider = MoyaProvider<GitHub>(requestClosure: endpointResolution, stubClosure: MoyaProvider.ImmediatelyStub)
            }
            
            it("executes the endpoint resolver") {
                let target: GitHub = .zen
                _ = provider.request(target) { _ in  }
                
                expect(executed).to(beTruthy())
            }
        }
        
        describe("a provider with error in request closure") {
            var provider: MoyaProvider<GitHub>!
            
            beforeEach {
                let endpointResolution: MoyaProvider<GitHub>.RequestClosure = { endpoint, done in
                    let underyingError = NSError(domain: "", code: 123, userInfo: nil)
                    done(.failure(.underlying(underyingError)))
                }
                provider = MoyaProvider<GitHub>(requestClosure: endpointResolution, stubClosure: MoyaProvider.ImmediatelyStub)
            }
            
            it("returns failure for any given request") {
                let target: GitHub = .zen
                var receivedError: Moya.Error?
                _ = provider.request(target) { response in
                    if case .failure(let error) = response {
                        receivedError = error
                    }
                }
                
                expect(receivedError).toEventuallyNot(beNil())
            }
        }
        
        describe("with stubbed errors") {
            var provider: MoyaProvider<GitHub>!
            beforeEach {
                provider = MoyaProvider(endpointClosure: failureEndpointClosure, stubClosure: MoyaProvider.ImmediatelyStub)
            }
            
            it("returns stubbed data for zen request") {
                var errored = false
                let target: GitHub = .zen

                waitUntil { done in
                    _ = provider.request(target) { result in
                        if case .failure = result {
                            errored = true
                        }
                        done()
                    }
                }
                
                let _ = target.sampleData
                expect(errored) == true
            }
            
            it("returns stubbed data for user profile request") {
                var errored = false

                let target: GitHub = .userProfile("ashfurrow")
                waitUntil { done in
                    _ = provider.request(target) { result in
                        if case .failure = result {
                            errored = true
                        }
                        done()
                    }
                }
                
                let _ = target.sampleData
                expect(errored) == true
            }
            
            it("returns stubbed error data when present") {
                var receivedError: Moya.Error?
                
                let target: GitHub = .userProfile("ashfurrow")
                _ = provider.request(target) { result in
                    if case let .failure(error) = result {
                        receivedError = error
                    }
                }
                
                switch receivedError {
                case .some(.underlying(let error)):
                    expect(error.localizedDescription) == "Houston, we have a problem"
                default:
                    fail("expected an Underlying error that Houston has a problem")
                }
            }
        }

        describe("struct targets") {
            struct StructAPI: TargetType {
                var baseURL = URL(string: "http://example.com")!
                var path = "/endpoint"
                var method = Moya.Method.GET
                var parameters: [String: Any]? = ["key": "value"]
                var task: Task = .request
                var sampleData = "sample data".data(using: .utf8)!
            }

            it("uses correct URL") {
                var requestedURL: String?
                let endpointResolution: MoyaProvider<StructTarget>.RequestClosure = { endpoint, done in
                    requestedURL = endpoint.URL
                    done(.success(endpoint.urlRequest))
                }
                let provider = MoyaProvider<StructTarget>(requestClosure: endpointResolution, stubClosure: MoyaProvider.ImmediatelyStub)

                waitUntil { done in
                    _ = provider.request(StructTarget(StructAPI())) { _ in
                        done()
                    }
                }

                expect(requestedURL) == "http://example.com/endpoint"
            }

            it("uses correct parameters") {
                var requestParameters: [String: Any]?
                let endpointResolution: MoyaProvider<StructTarget>.RequestClosure = { endpoint, done in
                    requestParameters = endpoint.parameters
                    done(.success(endpoint.urlRequest))
                }
                let provider = MoyaProvider<StructTarget>(requestClosure: endpointResolution, stubClosure: MoyaProvider.ImmediatelyStub)

                waitUntil { done in
                    _ = provider.request(StructTarget(StructAPI())) { _ in
                        done()
                    }
                }

                expect(requestParameters?.count) == 1
            }

            it("uses correct method") {
                var requestMethod: Moya.Method?
                let endpointResolution: MoyaProvider<StructTarget>.RequestClosure = { endpoint, done in
                    requestMethod = endpoint.method
                    done(.success(endpoint.urlRequest))
                }
                let provider = MoyaProvider<StructTarget>(requestClosure: endpointResolution, stubClosure: MoyaProvider.ImmediatelyStub)

                waitUntil { done in
                    _ = provider.request(StructTarget(StructAPI())) { _ in
                        done()
                    }
                }

                expect(requestMethod) == .GET
            }

            it("uses correct sample data") {
                var dataString: String?
                let provider = MoyaProvider<StructTarget>(stubClosure: MoyaProvider.ImmediatelyStub)

                waitUntil { done in
                    _ = provider.request(StructTarget(StructAPI())) { result in
                        if case let .success(response) = result {
                            dataString = String(data: response.data, encoding: .utf8)
                        }
                        done()
                    }
                }

                expect(dataString) == "sample data"
            }
        }
        
        describe("an inflight-tracking provider") {
            var provider: MoyaProvider<GitHub>!
            beforeEach {
                OHHTTPStubs.stubRequests(passingTest: {$0.url!.path == "/zen"}) { _ in
                    return OHHTTPStubsResponse(data: GitHub.zen.sampleData, statusCode: 200, headers: nil)
                }
                provider = MoyaProvider<GitHub>(trackInflights: true)
            }
            
            it("returns identical response for inflight requests") {
                let target: GitHub = .zen
                var receivedResponse: Moya.Response!
                
                expect(provider.inflightRequests.keys.count).to( equal(0) )
                
                _ = provider.request(target) { result in
                    if case let .success(response) = result {
                        receivedResponse = response
                    }
                    expect(provider.inflightRequests.count).to( equal(1) )
                }
                _ = provider.request(target) { result in
                    expect(receivedResponse).toNot( beNil() )
                    if case let .success(response) = result {
                        expect(receivedResponse).to( beIdenticalToResponse(response) )
                    }
                    expect(provider.inflightRequests.count).to( equal(1) )
                } as! CancellableWrapper

                // Allow for network request to complete
                expect(provider.inflightRequests.count).toEventually( equal(0) )
                
            }
        }
        
        describe("the cancellable token") {
            var provider: MoyaProvider<GitHub>!
            beforeEach{
                provider = MoyaProvider<GitHub>(stubClosure: MoyaProvider.DelayedStub(0.5))
            }
            
            it("invokes completion and returns .Failure if cancelled immediately") {
                var error: Moya.Error?
                waitUntil { done in
                    let cancellable = provider.request(GitHub.zen, completion: { (result) in
                        if case let .failure(err) = result {
                            error = err
                        }
                        done()
                    })
                    cancellable.cancel()
                }
                
                expect(error).toNot(beNil())
                
                let underlyingIsCancelled: Bool
                if let error = error, case .underlying(let err) = error {
                    underlyingIsCancelled = (err as NSError).code == NSURLErrorCancelled
                } else {
                    underlyingIsCancelled = false
                }
                
                expect(underlyingIsCancelled).to(beTrue())
            }
        }
    }
}
