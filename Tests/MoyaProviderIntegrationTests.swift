import Quick
import Nimble
import OHHTTPStubs
import Alamofire

@testable import Moya
@testable import ReactiveMoya

func beIdenticalToResponse(_ expectedValue: Moya.Response) -> MatcherFunc<Moya.Response> {
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
        let userMessage = String(data: GitHub.userProfile("ashfurrow").sampleData, encoding: .utf8)
        let zenMessage = String(data: GitHub.zen.sampleData, encoding: .utf8)
        
        beforeEach {
            OHHTTPStubs.stubRequests(passingTest: {$0.url!.path == "/zen"}) { _ in
                return OHHTTPStubsResponse(data: GitHub.zen.sampleData, statusCode: 200, headers: nil)
            }
            
            OHHTTPStubs.stubRequests(passingTest: {$0.url!.path == "/users/ashfurrow"}) { _ in
                return OHHTTPStubsResponse(data: GitHub.userProfile("ashfurrow").sampleData, statusCode: 200, headers: nil)
            }
            
            OHHTTPStubs.stubRequests(passingTest: {$0.url!.path == "/basic-auth/user/passwd"}) { _ in
                return OHHTTPStubsResponse(data: HTTPBin.basicAuth.sampleData, statusCode: 200, headers: nil)
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
                            provider.request(.zen) { result in
                                if case let .success(response) = result {
                                    message = String(data: response.data, encoding: .utf8)
                                }
                                done()
                            }
                        }
                        
                        expect(message) == zenMessage
                    }
                    
                    it("returns real data for user profile request") {
                        var message: String?

                        waitUntil { done in
                            let target: GitHub = .userProfile("ashfurrow")
                            provider.request(target) { result in
                                if case let .success(response) = result {
                                    message = String(data: response.data, encoding: .utf8)
                                }
                                done()
                            }
                        }
                        
                        expect(message) == userMessage
                    }

                    it("uses a custom Alamofire.Manager request generation") {
                        let manager = StubManager()
                        let provider = MoyaProvider<GitHub>(manager: manager)

                        waitUntil { done in
                            provider.request(.zen) { _ in done() }
                        }

                        expect(manager.called) == true
                    }
                    
                    it("uses other background queue") {
                        var isMainThread: Bool?
                        let queue = DispatchQueue(label: "background_queue", attributes: .concurrent)
                        let target: GitHub = .zen
                        
                        waitUntil { done in
                            provider.request(target, queue:queue) { _ in
                                isMainThread = Thread.isMainThread
                                done()
                            }
                        }
                        
                        expect(isMainThread) == false
                    }
                    
                    it("uses main queue") {
                        var isMainThread: Bool?
                        let target: GitHub = .zen
                        
                        waitUntil { done in 
                            provider.request(target) { _ in
                                isMainThread = Thread.isMainThread
                                done()
                            }
                        }
                        
                        expect(isMainThread) == true
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
                            provider.request(.basicAuth) { _ in done() }
                        }
                        
                        expect(called) == true
                    }
                    
                    it("credential closure returns valid username and password") {
                        var called = false
                        var returnedData: Data?
                        let plugin = CredentialsPlugin { _ in
                            called = true
                            return URLCredential(user: "user", password: "passwd", persistence: .none)
                        }
                        
                        let provider  = MoyaProvider<HTTPBin>(plugins: [plugin])
                        let target = HTTPBin.basicAuth

                        waitUntil { done in
                            provider.request(target) { result in
                                if case let .success(response) = result {
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
                            if change == .began {
                                called = true
                            }
                        }
                        
                        let provider = MoyaProvider<GitHub>(plugins: [plugin])
                        waitUntil { done in
                            provider.request(.zen) { _ in done() }
                        }
                        
                        expect(called) == true
                    }
                    
                    it("notifies at the end of network requests") {
                        var called = false
                        let plugin = NetworkActivityPlugin { change in
                            if change == .ended {
                                called = true
                            }
                        }
                        
                        let provider = MoyaProvider<GitHub>(plugins: [plugin])
                        waitUntil { done in
                            provider.request(.zen) { _ in done() }
                        }
                        
                        expect(called) == true
                    }
                }
                
                describe("a provider with network logger plugin") {
                    var log = ""
                    var plugin: NetworkLoggerPlugin!
                    beforeEach {
                        log = ""

                        plugin = NetworkLoggerPlugin(verbose: true, output: { (_, _, printing: Any...) in
                            //mapping the Any... from items to a string that can be compared
                            let stringArray: [String] = printing.map { $0 as? String }.flatMap { $0 }
                            let string: String = stringArray.reduce("") { $0 + $1 + " " }
                            log += string
                        })
                    }

                    it("logs the request") {
                        
                        let provider = MoyaProvider<GitHub>(plugins: [plugin])
                        waitUntil { done in
                            provider.request(.zen) { _ in done() }
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
            }
            
            describe("a reactive provider with SignalProducer") {
                var provider: ReactiveSwiftMoyaProvider<GitHub>!
                beforeEach {
                    provider = ReactiveSwiftMoyaProvider<GitHub>()
                }
                
                it("returns some data for zen request") {
                    var message: String?

                    waitUntil { done in
                        provider.request(.zen).startWithResult { result in
                            if case .success(let response) = result {
                                message = String(data: response.data, encoding: String.Encoding.utf8)
                                done()
                            }
                        }
                    }
                    
                    expect(message) == zenMessage
                }
                
                it("returns some data for user profile request") {
                    var message: String?

                    waitUntil { done in
                        let target: GitHub = .userProfile("ashfurrow")
                        provider.request(target).startWithResult { result in
                            if case .success(let response) = result {
                                message = String(data: response.data, encoding: String.Encoding.utf8)
                                done()
                            }
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

    override func request(_ urlRequest: URLRequestConvertible) -> DataRequest {
        called = true
        return super.request(urlRequest)
    }
}
