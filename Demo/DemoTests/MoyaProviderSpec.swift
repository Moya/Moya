import Quick
import Nimble
import Alamofire
import Moya

class MoyaProviderSpec: QuickSpec {
    override func spec() {
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
            expect(endpoint1.urlRequest).to(equal(endpoint2.urlRequest))
        }
        
        it("returns a cancellable object when a request is made") {
            let target: GitHub = .UserProfile("ashfurrow")
            
            let cancellable: Cancellable = provider.request(target) { (_, _, _, _) in }
            
            expect(cancellable).toNot(beNil())

        }

        it("uses the Alamofire.Manager.sharedInstance by default") {
            expect(provider.manager).to(beIdenticalTo(Alamofire.Manager.sharedInstance))
        }
                
        it("credential closure returns nil") {
            var called = false
            let provider = MoyaProvider<HTTPBin>(stubBehavior: MoyaProvider.ImmediateStubbingBehaviour, credentialClosure: { (target) -> NSURLCredential? in
                    called = true
                    return nil
            })
            
            let target: HTTPBin = .BasicAuth
            provider.request(target) { (data, statusCode, response, error) in }
            
            expect(called) == true
        }
        
        it("credential closure returns valid username and password") {
            var called = false
            let provider = MoyaProvider<HTTPBin>(stubBehavior: MoyaProvider.ImmediateStubbingBehaviour, credentialClosure: { (target) -> NSURLCredential? in
                called = true
                return NSURLCredential(user: "user", password: "passwd", persistence: .None)
            })
            
            let target: HTTPBin = .BasicAuth
            provider.request(target) { (data, statusCode, response, error) in }
            
            expect(called) == true
        }

        it("accepts a custom Alamofire.Manager") {
            let manager = Manager()
            let provider = MoyaProvider<GitHub>(manager: manager)

            expect(provider.manager).to(beIdenticalTo(manager))
        }

        it("uses a custom Alamofire.Manager for session challenges") {
            var called = false
            let manager = Manager()
            manager.delegate.sessionDidReceiveChallenge = { (session, challenge) in
                called = true
                let disposition: NSURLSessionAuthChallengeDisposition = .PerformDefaultHandling
                return (disposition, nil)
            }
            let provider = MoyaProvider<GitHub>(manager: manager)
            let target: GitHub = .Zen
            waitUntil(timeout: 3) { done in
                provider.request(target) { (data, statusCode, response, error) in
                    done()
                }
                return
            }

            expect(called) == true
        }

        it("notifies at the beginning of network requests") {
            var called = false
            let provider = MoyaProvider<GitHub>(stubBehavior: MoyaProvider.ImmediateStubbingBehaviour, networkActivityClosure: { (change) -> () in
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
            let provider = MoyaProvider<GitHub>(stubBehavior: MoyaProvider.ImmediateStubbingBehaviour, networkActivityClosure: { (change) -> () in
                if change == .Ended {
                    called = true
                }
            })

            let target: GitHub = .Zen
            provider.request(target) { (data, statusCode, response, error) in }
            
            expect(called) == true
        }

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

            expect {
                return endDate?.timeIntervalSinceDate(startDate)
            }.to( beGreaterThanOrEqualTo(NSTimeInterval(2)) )
        }

        describe("a provider with a custom endpoint resolver") {
            var provider: MoyaProvider<GitHub>!
            var executed = false
            
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

                expect(executed).to(beTruthy())
            }
        }

        describe("with stubbed errors") {
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

        describe("with lazy data") {
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
