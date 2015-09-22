import UIKit
import Quick
import Nimble
import ReactiveMoya
import OHHTTPStubs

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


func beIndenticalToResponse(expectedValue: MoyaResponse) -> MatcherFunc<MoyaResponse> {
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
                        provider.request(target) { (data, statusCode, response, error) in
                            if let data = data {
                                message = NSString(data: data, encoding: NSUTF8StringEncoding) as? String
                            }
                        }
                        
                        expect{message}.toEventually( equal(zenMessage) )
                    }
                    
                    it("returns real data for user profile request") {
                        var message: String?
                        
                        let target: GitHub = .UserProfile("ashfurrow")
                        provider.request(target) { (data, statusCode, response, error) in
                            if let data = data {
                                message = NSString(data: data, encoding: NSUTF8StringEncoding) as? String
                            }
                        }
                        
                        expect{message}.toEventually( equal(userMessage) )
                    }
                    
                    it("returns an error when cancelled") {
                        var receivedError: ErrorType?

                        let target: GitHub = .UserProfile("ashfurrow")
                        let token = provider.request(target) { (data, statusCode, response, error) in
                            receivedError = error
                        }
                        token.cancel()

                        expect(receivedError).toEventuallyNot( beNil() )
                    }
                }
                
                describe("a provider with credential closures") {
                    it("credential closure returns nil") {
                        var called = false
                        let provider  = MoyaProvider<HTTPBin>(credentialClosure: {(target) -> (NSURLCredential?) in
                            
                            called = true
                            return nil
                        })
                        
                        let target: HTTPBin = .BasicAuth
                        provider.request(target) { (data, statusCode, response, error) in }
                        
                        expect(called).toEventually( beTrue() )
                        
                    }
                    
                    it("credential closure returns valid username and password") {
                        var called = false
                        var returnedData: NSData?
                        let provider  = MoyaProvider<HTTPBin>(credentialClosure: {(target) -> (NSURLCredential?) in
                            
                            called = true
                            return NSURLCredential(user: "user", password: "passwd", persistence: .None)
                        })
                        
                        let target: HTTPBin = .BasicAuth
                        provider.request(target) { (data, statusCode, response, error) in
                            returnedData = data
                        }
                        
                        expect(called).toEventually( beTrue() )
                        expect(returnedData).toEventually(equal(target.sampleData))
                    }
                }

                describe("a provider with network activity closures") {
                    it("notifies at the beginning of network requests") {
                        var called = false
                        let provider = MoyaProvider<GitHub>(networkActivityClosure: { (change) -> () in
                            if change == .Began {
                                called = true
                            }
                        })

                        let target: GitHub = .Zen
                        provider.request(target) { (data, statusCode, response, error) in }

                        expect(called).toEventually( beTrue() )
                    }

                    it("notifies at the end of network requests") {
                        var called = false
                        let provider = MoyaProvider<GitHub>(networkActivityClosure: { (change) -> () in
                            if change == .Ended {
                                called = true
                            }
                        })

                        let target: GitHub = .Zen
                        provider.request(target) { (data, statusCode, response, error) in }

                        expect(called).toEventually( beTrue() )
                    }
                }
                
                describe("a reactive provider") {
                    var provider: ReactiveCocoaMoyaProvider<GitHub>!
                    beforeEach {
                        provider = ReactiveCocoaMoyaProvider<GitHub>()
                    }
                    
                    it("returns some data for zen request") {
                        var message: String?
                        
                        let target: GitHub = .Zen
                        provider.request(target).subscribeNext { (response) -> Void in
                            if let response = response as? MoyaResponse {
                                message = NSString(data: response.data, encoding: NSUTF8StringEncoding) as? String
                            }
                        }

                        expect{message}.toEventually( equal(zenMessage) )
                    }
                    
                    it("returns some data for user profile request") {
                        var message: String?
                        
                        let target: GitHub = .UserProfile("ashfurrow")
                        provider.request(target).subscribeNext { (response) -> Void in
                            if let response = response as? MoyaResponse {
                                message = NSString(data: response.data, encoding: NSUTF8StringEncoding) as? String
                            }
                        }

                        expect{message}.toEventually( equal(userMessage) )
                    }
                    
                    it("returns identical signals for inflight requests") {
                        let target: GitHub = .Zen
                        let signal1 = provider.request(target)
                        let signal2 = provider.request(target)
                        
                        expect(provider.inflightRequests.count).to(equal(0))
                        
                        var receivedResponse: MoyaResponse!
                        
                        signal1.subscribeNext { (response) -> Void in
                            receivedResponse = response as? MoyaResponse
                            expect(provider.inflightRequests.count).to(equal(1))
                        }
                        
                        signal2.subscribeNext { (response) -> Void in
                            expect(receivedResponse).toNot(beNil())
                            expect(receivedResponse).to(beIndenticalToResponse( response as! MoyaResponse) )
                            expect(provider.inflightRequests.count).to(equal(1))
                        }
                        
                        // Allow for network request to complete
                        expect(provider.inflightRequests.count).toEventually( equal(0) )
                    }
                }
            }
        }
    }
}
