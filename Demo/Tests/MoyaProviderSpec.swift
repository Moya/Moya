import Quick
import Nimble
import Alamofire
import Foundation
@testable import Moya

class MoyaProviderSpec: QuickSpec {
    override func spec() {
        var provider: MoyaProvider<GitHub>!
        beforeEach {
            provider = MoyaProvider<GitHub>(stubClosure: MoyaProvider.ImmediatelyStub)
        }
        
        it("returns stubbed data for zen request") {
            var message: String?
            
            let target: GitHub = .Zen
            provider.request(target) { result in
                if case let .Success(response) = result {
                    message = NSString(data: response.data, encoding: NSUTF8StringEncoding) as? String
                }
            }
            
            let sampleData = target.sampleData as NSData
            expect(message).to(equal(NSString(data: sampleData, encoding: NSUTF8StringEncoding)))
        }
        
        it("returns stubbed data for user profile request") {
            var message: String?
            
            let target: GitHub = .UserProfile("ashfurrow")
            provider.request(target) { result in
                if case let .Success(response) = result {
                    message = NSString(data: response.data, encoding: NSUTF8StringEncoding) as? String
                }
            }
            
            let sampleData = target.sampleData as NSData
            expect(message).to(equal(NSString(data: sampleData, encoding: NSUTF8StringEncoding)))
        }
        
        it("returns equivalent Endpoint instances for the same target") {
            let target: GitHub = .Zen
            
            let endpoint1 = provider.endpoint(target)
            let endpoint2 = provider.endpoint(target)
            expect(endpoint1.urlRequest).to(equal(endpoint2.urlRequest))
        }
        
        it("returns a cancellable object when a request is made") {
            let target: GitHub = .UserProfile("ashfurrow")
            
            let cancellable: Cancellable = provider.request(target) { _ in  }
            
            expect(cancellable).toNot(beNil())
            
        }
        
        it("uses a custom manager by default, startRequestsImmediately should be false") {
            expect(provider.manager).toNot(beNil())
            expect(provider.manager.startRequestsImmediately) == false
        }

        it("credential closure returns nil") {
            var called = false
            let plugin = CredentialsPlugin { (target) -> NSURLCredential? in
                called = true
                return nil
            }
            
            let provider = MoyaProvider<HTTPBin>(stubClosure: MoyaProvider.ImmediatelyStub, plugins: [plugin])
            let target: HTTPBin = .BasicAuth
            provider.request(target) { _ in  }
            
            expect(called) == true
        }
        
        it("credential closure returns valid username and password") {
            var called = false
            let plugin = CredentialsPlugin { (target) -> NSURLCredential? in
                called = true
                return NSURLCredential(user: "user", password: "passwd", persistence: .None)
            }
            
            let provider = MoyaProvider<HTTPBin>(stubClosure: MoyaProvider.ImmediatelyStub, plugins: [plugin])
            let target: HTTPBin = .BasicAuth
            provider.request(target) { _ in  }
            
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
                if change == .Began {
                    called = true
                }
            }
            
            let provider = MoyaProvider<GitHub>(stubClosure: MoyaProvider.ImmediatelyStub, plugins: [plugin])
            let target: GitHub = .Zen
            provider.request(target) { _ in  }
            
            expect(called) == true
        }
        
        it("notifies at the end of network requests") {
            var called = false
            let plugin = NetworkActivityPlugin { (change) -> () in
                if change == .Ended {
                    called = true
                }
            }
            
            let provider = MoyaProvider<GitHub>(stubClosure: MoyaProvider.ImmediatelyStub, plugins: [plugin])
            let target: GitHub = .Zen
            provider.request(target) { _ in  }
            
            expect(called) == true
        }

        describe("a provider with delayed stubs") {
            var provider: MoyaProvider<GitHub>!
            let delay: NSTimeInterval = 0.5

            beforeEach {
                provider = MoyaProvider<GitHub>(stubClosure: MoyaProvider.DelayedStub(delay))
            }

            it("delays execution") {
                let startDate = NSDate()
                var endDate: NSDate?
                let target: GitHub = .Zen
                waitUntil { done in
                    provider.request(target) { _ in
                        endDate = NSDate()
                        done()
                    }
                    return
                }

                expect(endDate?.timeIntervalSinceDate(startDate)) >= delay
            }

            it("returns an error when request is cancelled") {
                var receivedError: ErrorType?

                waitUntil { done in
                    let target: GitHub = .UserProfile("ashfurrow")
                    let token = provider.request(target) { result in
                        if case let .Failure(error) = result {
                            receivedError = error
                        }
                        done()
                    }
                    token.cancel()
                }
                
                expect(receivedError).toNot( beNil() )
            }

            it("returns success when request is not cancelled") {
                var receivedError: ErrorType?

                waitUntil { done in
                    let target: GitHub = .UserProfile("ashfurrow")
                    let token = provider.request(target) { result in
                        if case let .Failure(error) = result {
                            receivedError = error
                        }
                        done()
                    }
                }

                expect(receivedError).to( beNil() )
            }
        }

        describe("a provider with a delayed endpoint resolver") {
            let beforeRequest: NSTimeInterval = 0.05
            let requestTime: NSTimeInterval = 0.1
            let beforeResponse: NSTimeInterval = 0.15
            let responseTime: NSTimeInterval = 0.2
            let afterResponse: NSTimeInterval = 0.3
            var provider: MoyaProvider<GitHub>!

            func delay(delay: NSTimeInterval, block: () -> ()) {
                let killTimeOffset = Int64(CDouble(delay) * CDouble(NSEC_PER_SEC))
                let killTime = dispatch_time(DISPATCH_TIME_NOW, killTimeOffset)
                dispatch_after(killTime, dispatch_get_main_queue(), block)
            }

            beforeEach {
                let endpointResolution: MoyaProvider<GitHub>.RequestClosure = { endpoint, done in
                    delay(requestTime) {
                        done(.Success(endpoint.urlRequest))
                    }
                }
                provider = MoyaProvider<GitHub>(requestClosure: endpointResolution, stubClosure: MoyaProvider.DelayedStub(responseTime))
            }

            it("returns success eventually") {
                var receivedError: ErrorType?

                waitUntil { done in
                    let target: GitHub = .UserProfile("ashfurrow")
                    provider.request(target) { result in
                        if case let .Failure(error) = result {
                            receivedError = error
                        }
                        done()
                    }
                }

                expect(receivedError).to( beNil() )
            }

            it("never calls completion if cancelled immediately") {
                var receivedError: ErrorType?
                var calledCompletion = false

                waitUntil { done in
                    let target: GitHub = .UserProfile("ashfurrow")
                    let token = provider.request(target) { result in
                        calledCompletion = true
                        if case let .Failure(error) = result {
                            receivedError = error
                        }
                        done()
                    }
                    token.cancel()
                    delay(afterResponse) {
                        done()
                    }
                }

                expect(receivedError).to( beNil() )
                expect(calledCompletion).to( beFalse() )
            }

            it("never calls completion if cancelled before request is created") {
                var receivedError: ErrorType?
                var calledCompletion = false

                waitUntil { done in
                    let target: GitHub = .UserProfile("ashfurrow")
                    let token = provider.request(target) { result in
                        calledCompletion = true
                        if case let .Failure(error) = result {
                            receivedError = error
                        }
                        done()
                    }
                    delay(beforeRequest) {
                        token.cancel()
                    }
                    delay(afterResponse) {
                        done()
                    }
                }

                expect(receivedError).to( beNil() )
                expect(calledCompletion).to( beFalse() )
            }

            it("receives an error if request is cancelled before response comes back") {
                var receivedError: ErrorType?

                waitUntil { done in
                    let target: GitHub = .UserProfile("ashfurrow")
                    let token = provider.request(target) { result in
                        if case let .Failure(error) = result {
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
                    done(.Success(endpoint.urlRequest))
                }
                provider = MoyaProvider<GitHub>(requestClosure: endpointResolution, stubClosure: MoyaProvider.ImmediatelyStub)
            }
            
            it("executes the endpoint resolver") {
                let target: GitHub = .Zen
                provider.request(target) { _ in  }
                
                expect(executed).to(beTruthy())
            }
        }
        
        describe("a provider with error in request closure") {
            var provider: MoyaProvider<GitHub>!
            
            beforeEach {
                let endpointResolution: MoyaProvider<GitHub>.RequestClosure = { endpoint, done in
                    let underyingError = NSError(domain: "", code: 123, userInfo: nil)
                    done(.Failure(.Underlying(underyingError)))
                }
                provider = MoyaProvider<GitHub>(requestClosure: endpointResolution, stubClosure: MoyaProvider.ImmediatelyStub)
            }
            
            it("returns failure for any given request") {
                let target: GitHub = .Zen
                var receivedError: Moya.Error?
                provider.request(target) { response in
                    if case .Failure(let error) = response {
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
                let target: GitHub = .Zen

                waitUntil { done in
                    provider.request(target) { result in
                        if case .Failure = result {
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

                let target: GitHub = .UserProfile("ashfurrow")
                waitUntil { done in
                    provider.request(target) { result in
                        if case .Failure = result {
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
                
                let target: GitHub = .UserProfile("ashfurrow")
                provider.request(target) { result in
                    if case let .Failure(error) = result {
                        receivedError = error
                    }
                }
                
                switch receivedError {
                case .Some(.Underlying(let error)):
                    expect(error.localizedDescription) == "Houston, we have a problem"
                default:
                    fail("expected an Underlying error that Houston has a problem")
                }
            }
        }

        describe("struct targets") {
            struct StructAPI: TargetType {
                var baseURL = NSURL(string: "http://example.com")!
                var path = "/endpoint"
                var method = Moya.Method.GET
                var parameters: [String: AnyObject]? = ["key": "value"]
                var multipartBody: [Moya.MultipartFormData]? = []
                var sampleData = ("sample data" as NSString).dataUsingEncoding(NSUTF8StringEncoding)!
            }

            it("uses correct URL") {
                var requestedURL: String?
                let endpointResolution: MoyaProvider<StructTarget>.RequestClosure = { endpoint, done in
                    requestedURL = endpoint.URL
                    done(.Success(endpoint.urlRequest))
                }
                let provider = MoyaProvider<StructTarget>(requestClosure: endpointResolution, stubClosure: MoyaProvider.ImmediatelyStub)

                waitUntil { done in
                    provider.request(StructTarget(StructAPI())) { _ in
                        done()
                    }
                }

                expect(requestedURL) == "http://example.com/endpoint"
            }

            it("uses correct parameters") {
                var requestParameters: [String: AnyObject]?
                let endpointResolution: MoyaProvider<StructTarget>.RequestClosure = { endpoint, done in
                    requestParameters = endpoint.parameters
                    done(.Success(endpoint.urlRequest))
                }
                let provider = MoyaProvider<StructTarget>(requestClosure: endpointResolution, stubClosure: MoyaProvider.ImmediatelyStub)

                waitUntil { done in
                    provider.request(StructTarget(StructAPI())) { _ in
                        done()
                    }
                }

                expect(requestParameters?.count) == 1
            }

            it("uses correct method") {
                var requestMethod: Moya.Method?
                let endpointResolution: MoyaProvider<StructTarget>.RequestClosure = { endpoint, done in
                    requestMethod = endpoint.method
                    done(.Success(endpoint.urlRequest))
                }
                let provider = MoyaProvider<StructTarget>(requestClosure: endpointResolution, stubClosure: MoyaProvider.ImmediatelyStub)

                waitUntil { done in
                    provider.request(StructTarget(StructAPI())) { _ in
                        done()
                    }
                }

                expect(requestMethod) == .GET
            }

            it("uses correct sample data") {
                var dataString: NSString?
                let provider = MoyaProvider<StructTarget>(stubClosure: MoyaProvider.ImmediatelyStub)

                waitUntil { done in
                    provider.request(StructTarget(StructAPI())) { result in
                        if case let .Success(response) = result {
                            dataString = NSString(data: response.data, encoding: NSUTF8StringEncoding)
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
                provider = MoyaProvider<GitHub>(trackInflights: true)
            }
            
            it("returns identical response for inflight requests") {
                let target: GitHub = .Zen
                var receivedResponse: Moya.Response!
                
                expect(provider.inflightRequests.keys.count).to(equal(0))
                
                provider.request(target) { result in
                    if case let .Success(response) = result {
                        receivedResponse = response
                    }
                    expect(provider.inflightRequests.count).to(equal(1))
                }
                let request2: CancellableWrapper = provider.request(target) { result in
                    expect(receivedResponse).toNot(beNil())
                    if case let .Success(response) = result {
                        expect(receivedResponse).to(beIndenticalToResponse(response))
                    }
                    expect(provider.inflightRequests.count).to(equal(1))
                } as! CancellableWrapper

                // Allow for network request to complete
                expect(provider.inflightRequests.count).toEventually( equal(0))
                
            }
        }
    }
}
