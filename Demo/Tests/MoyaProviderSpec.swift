import Quick
import Nimble
import Alamofire
import Moya
import Foundation

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
        
        it("delays execution when appropriate") {
            let provider = MoyaProvider<GitHub>(stubClosure: MoyaProvider.DelayedStub(2))
            
            let startDate = NSDate()
            var endDate: NSDate?
            let target: GitHub = .Zen
            waitUntil(timeout: 3) { done in
                provider.request(target) { _ in
                    endDate = NSDate()
                    done()
                }
                return
            }
            
            expect(endDate?.timeIntervalSinceDate(startDate)).to( beGreaterThanOrEqualTo(NSTimeInterval(2)) )
        }
        
        describe("a provider with a custom endpoint resolver") {
            var provider: MoyaProvider<GitHub>!
            var executed = false
            
            beforeEach {
                executed = false
                let endpointResolution = { (endpoint: Endpoint<GitHub>, done: NSURLRequest -> Void) in
                    executed = true
                    done(endpoint.urlRequest)
                }
                provider = MoyaProvider<GitHub>(requestClosure: endpointResolution, stubClosure: MoyaProvider.ImmediatelyStub)
            }
            
            it("executes the endpoint resolver") {
                let target: GitHub = .Zen
                provider.request(target) { _ in  }
                
                expect(executed).to(beTruthy())
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
                case .Some(.Underlying(let error as NSError)):
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
                var sampleData = ("sample data" as NSString).dataUsingEncoding(NSUTF8StringEncoding)!
            }

            it("uses correct URL") {
                var requestedURL: String?
                let endpointResolution = { (endpoint: Endpoint<StructTarget>, done: NSURLRequest -> Void) in
                    requestedURL = endpoint.URL
                    done(endpoint.urlRequest)
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
                let endpointResolution = { (endpoint: Endpoint<StructTarget>, done: NSURLRequest -> Void) in
                    requestParameters = endpoint.parameters
                    done(endpoint.urlRequest)
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
                let endpointResolution = { (endpoint: Endpoint<StructTarget>, done: NSURLRequest -> Void) in
                    requestMethod = endpoint.method
                    done(endpoint.urlRequest)
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
    }
}
