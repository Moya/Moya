import Quick
import Nimble
import ReactiveCocoa
import ReactiveMoya
import Alamofire

class ReactiveCocoaMoyaProviderSpec: QuickSpec {
    override func spec() {
        var provider: ReactiveCocoaMoyaProvider<GitHub>!
        beforeEach {
            provider = ReactiveCocoaMoyaProvider<GitHub>(stubBehavior: MoyaProvider.ImmediateStubbingBehaviour)
        }

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

        it("returns identical signals for inflight requests") {
            let target: GitHub = .Zen

            // The synchronous nature of stubbed responses makes this kind of tricky. We use the
            // subscribeNext closure to get the provider into a state where the signal has been
            // added to the inflightRequests dictionary. Then we ask for an identical request,
            // which should return the same signal. We can't *test* those signals equivalency
            // due to the use of RACSignal.defer, but we can check if the number of inflight
            // requests went up or not.

            let outerSignal = provider.request(target)
            outerSignal.subscribeNext { (object) -> Void in
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

        describe("failing") {
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

            it("returns errpr for zen request") {
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

            class TestProvider<T: MoyaTarget>: ReactiveCocoaMoyaProvider<T> {
                override init(endpointClosure: MoyaEndpointsClosure = MoyaProvider.DefaultEndpointMapping, endpointResolver: MoyaEndpointResolution = MoyaProvider.DefaultEndpointResolution, stubBehavior: MoyaStubbedBehavior = MoyaProvider.NoStubbingBehavior, credentialClosure: MoyaCredentialClosure? = nil, networkActivityClosure: Moya.NetworkActivityClosure? = nil, manager: Manager = Alamofire.Manager.sharedInstance) {
                    super.init(endpointClosure: endpointClosure, endpointResolver: endpointResolver, stubBehavior: stubBehavior, networkActivityClosure: networkActivityClosure, credentialClosure: credentialClosure, manager: manager)
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
    var parameters: [String: AnyObject] {
        return [:]
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

private let lazyEndpointClosure = { (target: GitHub) -> Endpoint<GitHub> in
    return Endpoint<GitHub>(URL: url(target), sampleResponse: .Closure({.Success(200, {target.sampleData})}), method: target.method, parameters: target.parameters)
}

private let failureEndpointClosure = { (target: GitHub) -> Endpoint<GitHub> in
    let errorData = "Houston, we have a problem".dataUsingEncoding(NSUTF8StringEncoding)!
    return Endpoint<GitHub>(URL: url(target), sampleResponse: .Error(401, NSError(domain: "com.moya.error", code: 0, userInfo: nil), {errorData}), method: target.method, parameters: target.parameters)
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
    var parameters: [String: AnyObject] {
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
