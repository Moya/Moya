import Quick
import Nimble
import ReactiveCocoa
import ReactiveMoya
import Alamofire

class ReactiveCocoaMoyaProviderSpec: QuickSpec {
    override func spec() {
        var provider: ReactiveCocoaMoyaProvider<GitHub>!
        beforeEach {
            provider = ReactiveCocoaMoyaProvider<GitHub>(stubClosure: MoyaProvider.ImmediatelyStub)
        }
        
        describe("provider with RACSignal") {
            
            it("returns a MoyaResponse object") {
                var called = false
                
                provider.request(.Zen).subscribeNext { (object) -> Void in
                    if let _ = object as? MoyaResponse {
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
                
                _ = target.sampleData as NSData
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
                
                expect(receivedResponse) == sampleResponse
            }
        }

        describe("failing") {
            var provider: ReactiveCocoaMoyaProvider<GitHub>!
            beforeEach {
                provider = ReactiveCocoaMoyaProvider<GitHub>(endpointClosure: failureEndpointClosure, stubClosure: MoyaProvider.ImmediatelyStub)
            }

            it("returns the correct error message") {
                var receivedError: NSError!

                waitUntil { done in
                    provider.request(.Zen).subscribeError { (error) -> Void in
                        receivedError = error
                        done()
                    }
                }

                expect(receivedError.domain) == "com.moya.error"
            }

            it("returns an error") {
                var errored = false

                let target: GitHub = .Zen
                provider.request(target).subscribeError { (error) -> Void in
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

            class TestProvider<Target: MoyaTarget>: ReactiveCocoaMoyaProvider<Target> {
                override init(endpointClosure: EndpointClosure = MoyaProvider.DefaultEndpointMapping,
                    requestClosure: RequestClosure = MoyaProvider.DefaultRequestMapping,
                    stubClosure: StubClosure = MoyaProvider.NeverStub,
                    manager: Manager = Alamofire.Manager.sharedInstance,
                    plugins: [Plugin<Target>] = []) {

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

                let disposable = provider.request(target).subscribeCompleted { () -> Void in
                    // Should never be executed
                    fail()
                }
                disposable.dispose()

                expect(TestCancellable.cancelled).to( beTrue() )
            }
        }

        describe("provider with SignalProducer") {

            it("returns a MoyaResponse object") {
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
                
                class TestProvider<Target: MoyaTarget>: ReactiveCocoaMoyaProvider<Target> {
                    override init(endpointClosure: EndpointClosure = MoyaProvider.DefaultEndpointMapping,
                        requestClosure: RequestClosure = MoyaProvider.DefaultRequestMapping,
                        stubClosure: StubClosure = MoyaProvider.NeverStub,
                        manager: Manager = Alamofire.Manager.sharedInstance,
                        plugins: [Plugin<Target>] = []) {

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
    }
}

private extension String {
    var URLEscapedString: String {
        return self.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLHostAllowedCharacterSet())!
    }
}

private enum GitHub {
    case Zen
    case UserProfile(String)
}

extension GitHub : MoyaTarget {
    var baseURL: NSURL { return NSURL(string: "https://api.github.com")! }
    var path: String {
        switch self {
        case .Zen:
            return "/zen"
        case .UserProfile(let name):
            return "/users/\(name.URLEscapedString)"
        }
    }
    var method: Moya.Method {
        return .GET
    }
    var parameters: [String: AnyObject]? {
        return nil
    }
    var sampleData: NSData {
        switch self {
        case .Zen:
            return "Half measures are as bad as nothing at all.".dataUsingEncoding(NSUTF8StringEncoding)!
        case .UserProfile(let name):
            return "{\"login\": \"\(name)\", \"id\": 100}".dataUsingEncoding(NSUTF8StringEncoding)!
        }
    }
}

private func url(route: MoyaTarget) -> String {
    return route.baseURL.URLByAppendingPathComponent(route.path).absoluteString
}

private let failureEndpointClosure = { (target: GitHub) -> Endpoint<GitHub> in
    let error = NSError(domain: "com.moya.error", code: 0, userInfo: [NSLocalizedDescriptionKey: "Houston, we have a problem"])
    return Endpoint<GitHub>(URL: url(target), sampleResponseClosure: {.NetworkError(error)}, method: target.method, parameters: target.parameters)
}

private enum HTTPBin: MoyaTarget {
    case BasicAuth

    var baseURL: NSURL { return NSURL(string: "http://httpbin.org")! }
    var path: String {
        switch self {
        case .BasicAuth:
            return "/basic-auth/user/passwd"
        }
    }

    var method: Moya.Method {
        return .GET
    }
    var parameters: [String: AnyObject]? {
        switch self {
        default:
            return [:]
        }
    }

    var sampleData: NSData {
        switch self {
        case .BasicAuth:
            return "{\"authenticated\": true, \"user\": \"user\"}".dataUsingEncoding(NSUTF8StringEncoding)!
        }
    }
}
