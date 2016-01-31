import Quick
import Moya
import Nimble
import OHHTTPStubs
import Alamofire

func beIndenticalToResponse(expectedValue: Moya.Response) -> MatcherFunc<Moya.Response> {
    return MatcherFunc { actualExpression, failureMessage in
        do {
            let instance = try actualExpression.evaluate()
            return instance === expectedValue
        } catch {
            return false
        }
    }
}

class MoyaProviderIntegrationTests: QuickSpec {
    override func spec() {
        let userMessage = NSString(data: GitHub.UserProfile("ashfurrow").sampleData, encoding: NSUTF8StringEncoding)
        let zenMessage = NSString(data: GitHub.Zen.sampleData, encoding: NSUTF8StringEncoding)
        
        beforeEach {
            OHHTTPStubs.stubRequestsPassingTest({$0.URL!.path == "/zen"}) { _ in
                return OHHTTPStubsResponse(data: GitHub.Zen.sampleData, statusCode: 200, headers: nil).responseTime(0.5)
            }
            
            OHHTTPStubs.stubRequestsPassingTest({$0.URL!.path == "/users/ashfurrow"}) { _ in
                return OHHTTPStubsResponse(data: GitHub.UserProfile("ashfurrow").sampleData, statusCode: 200, headers: nil).responseTime(0.5)
            }
            
            OHHTTPStubs.stubRequestsPassingTest({$0.URL!.path == "/basic-auth/user/passwd"}) { _ in
                return OHHTTPStubsResponse(data: HTTPBin.BasicAuth.sampleData, statusCode: 200, headers: nil)
            }
            
        }
        
        afterEach {
            OHHTTPStubs.removeAllStubs()
        }
        
        describe("valid endpoints") {
            describe("with live data") {
                describe("a provider") {
                    var provider: MoyaProvider<GitHub>!
                    beforeEach {
                        provider = MoyaProvider<GitHub>()
                    }
                    
                    it("returns real data for zen request") {
                        var message: String?

                        waitUntil { done in
                            provider.request(.Zen) { result in
                                if case let .Success(response) = result {
                                    message = NSString(data: response.data, encoding: NSUTF8StringEncoding) as? String
                                }
                                done()
                            }
                        }
                        
                        expect(message) == zenMessage
                    }
                    
                    it("returns real data for user profile request") {
                        var message: String?

                        waitUntil { done in
                            let target: GitHub = .UserProfile("ashfurrow")
                            provider.request(target) { result in
                                if case let .Success(response) = result {
                                    message = NSString(data: response.data, encoding: NSUTF8StringEncoding) as? String
                                }
                                done()
                            }
                        }
                        
                        expect(message) == userMessage
                    }
                    
                    it("returns an error when cancelled") {
                        var receivedError: ErrorType?

                        waitUntil { done in
                            let target: GitHub = .UserProfile("ashfurrow")
                            let token = provider.request(target) { result in
                                if case let .Failure(error) = result {
                                    receivedError = error
                                    done()
                                }
                            }
                            token.cancel()
                        }
                        
                        expect(receivedError).toNot( beNil() )
                    }

                    it("uses a custom Alamofire.Manager request generation") {
                        let manager = StubManager()
                        let provider = MoyaProvider<GitHub>(manager: manager)

                        waitUntil { done in
                            provider.request(GitHub.Zen) { _ in done() }
                        }

                        expect(manager.called) == true
                    }
                }
                
                describe("a provider with credential plugin") {
                    it("credential closure returns nil") {
                        var called = false
                        let plugin = CredentialsPlugin { _ in
                            called = true
                            return nil
                        }
                        
                        let provider  = MoyaProvider<HTTPBin>(plugins: [plugin])
                        expect(provider.plugins.count).to(equal(1))

                        waitUntil { done in
                            provider.request(.BasicAuth) { _ in done() }
                        }
                        
                        expect(called) == true
                    }
                    
                    it("credential closure returns valid username and password") {
                        var called = false
                        var returnedData: NSData?
                        let plugin = CredentialsPlugin { _ in
                            called = true
                            return NSURLCredential(user: "user", password: "passwd", persistence: .None)
                        }
                        
                        let provider  = MoyaProvider<HTTPBin>(plugins: [plugin])
                        let target = HTTPBin.BasicAuth

                        waitUntil { done in
                            provider.request(target) { result in
                                if case let .Success(response) = result {
                                    returnedData = response.data
                                }
                                done()
                            }
                        }
                        
                        expect(called) == true
                        expect(returnedData) == target.sampleData
                    }
                }
                
                describe("a provider with network activity plugin") {
                    it("notifies at the beginning of network requests") {
                        var called = false
                        let plugin = NetworkActivityPlugin { change in
                            if change == .Began {
                                called = true
                            }
                        }
                        
                        let provider = MoyaProvider<GitHub>(plugins: [plugin])
                        waitUntil { done in
                            provider.request(.Zen) { _ in done() }
                        }
                        
                        expect(called) == true
                    }
                    
                    it("notifies at the end of network requests") {
                        var called = false
                        let plugin = NetworkActivityPlugin { change in
                            if change == .Ended {
                                called = true
                            }
                        }
                        
                        let provider = MoyaProvider<GitHub>(plugins: [plugin])
                        waitUntil { done in
                            provider.request(.Zen) { _ in done() }
                        }
                        
                        expect(called) == true
                    }
                }
                
                describe("a provider with network logger plugin") {
                    var log = ""
                    var plugin: NetworkLoggerPlugin!
                    beforeEach {
                        log = ""

                        plugin = NetworkLoggerPlugin(verbose: true, output: { printing in
                            //mapping the Any... from items to a string that can be compared
                            let stringArray: [String] = printing.items.map { $0 as? String }.flatMap { $0 }
                            let string: String = stringArray.reduce("") { $0 + $1 + " " }
                            log += string
                        })
                    }

                    it("logs the request") {
                        
                        let provider = MoyaProvider<GitHub>(plugins: [plugin])
                        waitUntil { done in
                            provider.request(GitHub.Zen) { _ in done() }
                        }

                        expect(log).to( contain("Request:") )
                        expect(log).to( contain("{ URL: https://api.github.com/zen }") )
                        expect(log).to( contain("Request Headers: [:]") )
                        expect(log).to( contain("HTTP Request Method: GET") )
                        expect(log).to( contain("Response:") )
                        expect(log).to( contain("{ URL: https://api.github.com/zen } { status code: 200, headers") )
                        expect(log).to( contain("\"Content-Length\" = 43;") )
                    }
                }
                
                describe("a reactive provider with RACSignal") {
                    var provider: ReactiveCocoaMoyaProvider<GitHub>!
                    beforeEach {
                        provider = ReactiveCocoaMoyaProvider<GitHub>()
                    }
                    
                    it("returns some data for zen request") {
                        var message: String?

                        waitUntil { done in
                            provider.request(GitHub.Zen).subscribeNext { response in
                                if let response = response as? Moya.Response {
                                    message = NSString(data: response.data, encoding: NSUTF8StringEncoding) as? String
                                }

                                done()
                            }
                        }
                        
                        expect(message) == zenMessage
                    }
                    
                    it("returns some data for user profile request") {
                        var message: String?

                        waitUntil { done in
                            let target: GitHub = .UserProfile("ashfurrow")
                            provider.request(target).subscribeNext { response in
                                if let response = response as? Moya.Response {
                                    message = NSString(data: response.data, encoding: NSUTF8StringEncoding) as? String
                                }

                                done()
                            }
                        }
                        
                        expect(message) == userMessage
                    }
                }
            }
            
            describe("a reactive provider with SignalProducer") {
                var provider: ReactiveCocoaMoyaProvider<GitHub>!
                beforeEach {
                    provider = ReactiveCocoaMoyaProvider<GitHub>()
                }
                
                it("returns some data for zen request") {
                    var message: String?

                    waitUntil { done in
                        provider.request(.Zen).startWithNext { response in
                            message = NSString(data: response.data, encoding: NSUTF8StringEncoding) as? String
                            done()
                        }
                    }
                    
                    expect(message) == zenMessage
                }
                
                it("returns some data for user profile request") {
                    var message: String?

                    waitUntil { done in
                        let target: GitHub = .UserProfile("ashfurrow")
                        provider.request(target).startWithNext { response in
                            message = NSString(data: response.data, encoding: NSUTF8StringEncoding) as? String
                            done()
                        }
                    }
                    
                    expect(message) == userMessage
                }
            }
        }
    }
}

class StubManager: Manager {
    var called = false

    override func request(URLRequest: URLRequestConvertible) -> Request {
        called = true
        return super.request(URLRequest)
    }
}
