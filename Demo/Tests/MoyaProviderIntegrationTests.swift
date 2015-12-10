import Quick
import Moya
import Nimble
import OHHTTPStubs

func beIndenticalToResponse(expectedValue: Response) -> MatcherFunc<Response> {
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
                        return
                    }
                    
                    it("returns real data for zen request") {
                        var message: String?
                        
                        let target: GitHub = .Zen
                        provider.request(target) { result in
                            if case let .Success(response) = result {
                                message = NSString(data: response.data, encoding: NSUTF8StringEncoding) as? String
                            }
                        }
                        
                        expect{message}.toEventually( equal(zenMessage) )
                    }
                    
                    it("returns real data for user profile request") {
                        var message: String?
                        
                        let target: GitHub = .UserProfile("ashfurrow")
                        provider.request(target) { result in
                            if case let .Success(response) = result {
                                message = NSString(data: response.data, encoding: NSUTF8StringEncoding) as? String
                            }
                        }
                        
                        expect{message}.toEventually( equal(userMessage) )
                    }
                    
                    it("returns an error when cancelled") {
                        var receivedError: ErrorType?
                        
                        let target: GitHub = .UserProfile("ashfurrow")
                        let token = provider.request(target) { result in
                            if case let .Failure(error) = result {
                                receivedError = error
                            }
                        }
                        token.cancel()
                        
                        expect(receivedError).toEventuallyNot( beNil() )
                    }
                }
                
                describe("a provider with credential plugin") {
                    it("credential closure returns nil") {
                        var called = false
                        let plugin = CredentialsPlugin { (target) -> (NSURLCredential?) in
                            called = true
                            return nil
                        }
                        
                        let provider  = MoyaProvider<HTTPBin>(plugins: [plugin])
                        expect(provider.plugins.count).to(equal(1))
                        
                        let target: HTTPBin = .BasicAuth
                        provider.request(target) { _ in  }
                        
                        expect(called).toEventually( beTrue() )
                        
                    }
                    
                    it("credential closure returns valid username and password") {
                        var called = false
                        var returnedData: NSData?
                        let plugin = CredentialsPlugin { (target) -> (NSURLCredential?) in
                            called = true
                            return NSURLCredential(user: "user", password: "passwd", persistence: .None)
                        }
                        
                        let provider  = MoyaProvider<HTTPBin>(plugins: [plugin])
                        let target: HTTPBin = .BasicAuth
                        provider.request(target) { result in
                            if case let .Success(response) = result {
                                returnedData = response.data
                            }
                        }
                        
                        expect(called).toEventually( beTrue() )
                        expect(returnedData).toEventually(equal(target.sampleData))
                    }
                }
                
                describe("a provider with network activity plugin") {
                    it("notifies at the beginning of network requests") {
                        var called = false
                        let plugin = NetworkActivityPlugin { (change) -> () in
                            if change == .Began {
                                called = true
                            }
                        }
                        
                        let provider = MoyaProvider<GitHub>(plugins: [plugin])
                        let target: GitHub = .Zen
                        provider.request(target) { _ in  }
                        
                        expect(called).toEventually( beTrue() )
                    }
                    
                    it("notifies at the end of network requests") {
                        var called = false
                        let plugin = NetworkActivityPlugin { (change) -> () in
                            if change == .Ended {
                                called = true
                            }
                        }
                        
                        let provider = MoyaProvider<GitHub>(plugins: [plugin])
                        let target: GitHub = .Zen
                        provider.request(target) { _ in  }
                        
                        expect(called).toEventually( beTrue() )
                    }
                }
                
                describe("a provider with network logger plugin") {
                    
                    it("logs the request") {
                        var log = ""
                        let plugin = NetworkLoggerPlugin(verbose: true, output: { printing in
                            //mapping the Any... from items to a string that can be compared
                            let stringArray: [String] = printing.items.reduce([String]()) { $0 + ($1 as! [String]) }
                            let string: String = stringArray.reduce("") { $0 + $1 + " " }
                            log += string
                        })
                        
                        let provider = MoyaProvider<GitHub>(plugins: [plugin])
                        provider.request(GitHub.Zen) { _ in  }
                        
                        expect(log).toEventually(contain("Request:"))
                        expect(log).toEventually(contain("{ URL: https://api.github.com/zen }"))
                        expect(log).toEventually(contain("Request Headers: [:]"))
                        expect(log).toEventually(contain("HTTP Request Method: GET"))
                        expect(log).toEventually(contain("Response:"))
                        expect(log).toEventually(contain("{ URL: https://api.github.com/zen } { status code: 200, headers"))
                        expect(log).toEventually(contain("\"Content-Length\" = 43;"))
                    }
                }
                
                describe("a reactive provider with RACSignal") {
                    var provider: ReactiveCocoaMoyaProvider<GitHub>!
                    beforeEach {
                        provider = ReactiveCocoaMoyaProvider<GitHub>()
                    }
                    
                    it("returns some data for zen request") {
                        var message: String?
                        
                        let target: GitHub = .Zen
                        provider.request(target).subscribeNext { (response) -> Void in
                            if let response = response as? Response {
                                message = NSString(data: response.data, encoding: NSUTF8StringEncoding) as? String
                            }
                        }
                        
                        expect{message}.toEventually( equal(zenMessage) )
                    }
                    
                    it("returns some data for user profile request") {
                        var message: String?
                        
                        let target: GitHub = .UserProfile("ashfurrow")
                        provider.request(target).subscribeNext { (response) -> Void in
                            if let response = response as? Response {
                                message = NSString(data: response.data, encoding: NSUTF8StringEncoding) as? String
                            }
                        }
                        
                        expect{message}.toEventually( equal(userMessage) )
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
                    
                    let target: GitHub = .Zen
                    provider.request(target).startWithNext { (response) -> Void in
                        message = NSString(data: response.data, encoding: NSUTF8StringEncoding) as? String
                    }
                    
                    expect{message}.toEventually( equal(zenMessage) )
                }
                
                it("returns some data for user profile request") {
                    var message: String?
                    
                    let target: GitHub = .UserProfile("ashfurrow")
                    provider.request(target).startWithNext { (response) -> Void in
                        message = NSString(data: response.data, encoding: NSUTF8StringEncoding) as? String
                    }
                    
                    expect{message}.toEventually( equal(userMessage) )
                }
            }
        }
    }
}
