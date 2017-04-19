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
            provider = MoyaProvider<GitHub>(stubClosure: MoyaProvider.immediatelyStub)
        }
        
        it("returns stubbed data for zen request") {
            var message: String?
            
            let target: GitHub = .zen
            provider.request(target) { result in
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
            provider.request(target) { result in
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
            expect(endpoint1.urlRequest).toNot(beNil())
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
            
            let provider = MoyaProvider<HTTPBin>(stubClosure: MoyaProvider.immediatelyStub, plugins: [plugin])
            let target: HTTPBin = .basicAuth
            provider.request(target) { _ in  }
            
            expect(called) == true
        }
        
        it("credential closure returns valid username and password") {
            var called = false
            let plugin = CredentialsPlugin { (target) -> URLCredential? in
                called = true
                return URLCredential(user: "user", password: "passwd", persistence: .none)
            }
            
            let provider = MoyaProvider<HTTPBin>(stubClosure: MoyaProvider.immediatelyStub, plugins: [plugin])
            let target: HTTPBin = .basicAuth
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
                if change == .began {
                    called = true
                }
            }
            
            let provider = MoyaProvider<GitHub>(stubClosure: MoyaProvider.immediatelyStub, plugins: [plugin])
            let target: GitHub = .zen
            provider.request(target) { _ in  }
            
            expect(called) == true
        }
        
        it("notifies at the end of network requests") {
            var called = false
            let plugin = NetworkActivityPlugin { (change) -> () in
                if change == .ended {
                    called = true
                }
            }
            
            let provider = MoyaProvider<GitHub>(stubClosure: MoyaProvider.immediatelyStub, plugins: [plugin])
            let target: GitHub = .zen
            provider.request(target) { _ in  }
            
            expect(called) == true
        }

        it("uses the target's parameter encoding") {
            let endpoint = MoyaProvider.defaultEndpointMapping(for: GitHub.zen)
            expect(endpoint.parameterEncoding is JSONEncoding) == true
        }

        describe("a provider with delayed stubs") {
            var provider: MoyaProvider<GitHub>!
            var plugin: TestingPlugin!
            let delay: TimeInterval = 0.5

            beforeEach {
                plugin = TestingPlugin()
                provider = MoyaProvider<GitHub>(stubClosure: MoyaProvider.delayedStub(delay), plugins: [plugin])
            }

            it("delays execution") {
                let startDate = Date()
                var endDate: Date?
                let target: GitHub = .zen
                waitUntil { done in
                    provider.request(target) { _ in
                        endDate = Date()
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

            it("prepares the request using plugins") {
                waitUntil { done in
                    let target: GitHub = .userProfile("ashfurrow")
                    let token = provider.request(target) { _ in
                        done()
                    }
                }
                expect(plugin.didPrepare).to( beTrue() )
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

            it("processes the response with plugins") {
                var receivedStatusCode: Int?
                waitUntil { done in
                    let target: GitHub = .userProfile("ashfurrow")
                    let token = provider.request(target) { result in
                        if case let .success(response) = result {
                            receivedStatusCode = response.statusCode
                        }
                        done()
                    }
                }

                expect(receivedStatusCode).to( equal(-1) )
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
                        if let urlRequest = endpoint.urlRequest {
                            done(.success(urlRequest))
                        } else {
                            done(.failure(MoyaError.requestMapping(endpoint.url)))
                        }
                    }
                }
                provider = MoyaProvider<GitHub>(requestClosure: endpointResolution, stubClosure: MoyaProvider.delayedStub(responseTime))
            }

            it("returns success eventually") {
                var receivedError: Swift.Error?

                waitUntil { done in
                    let target: GitHub = .userProfile("ashfurrow")
                    provider.request(target) { result in
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
                    if let urlRequest = endpoint.urlRequest {
                        done(.success(urlRequest))
                    } else {
                        done(.failure(MoyaError.requestMapping(endpoint.url)))
                    }
                }
                provider = MoyaProvider<GitHub>(requestClosure: endpointResolution, stubClosure: MoyaProvider.immediatelyStub)
            }
            
            it("executes the endpoint resolver") {
                let target: GitHub = .zen
                provider.request(target) { _ in  }
                
                expect(executed).to(beTruthy())
            }
        }

        describe("a provider with custom sample response closures") {
            it("returns sample data") {
                let endpointResolution: MoyaProvider<GitHub>.EndpointClosure = { target in
                    let url = target.baseURL.appendingPathComponent(target.path).absoluteString
                    return Endpoint(url: url, sampleResponseClosure: {.networkResponse(200, target.sampleData)}, method: target.method, parameters: target.parameters)
                }
                let provider = MoyaProvider<GitHub>(endpointClosure: endpointResolution, stubClosure: MoyaProvider.immediatelyStub)

                var data: Data?
                provider.request(.zen) { result in
                    if case .success(let response) = result {
                        data = response.data
                    }
                }

                expect(data) == GitHub.zen.sampleData
            }

            it("returns identical sample response") {
                let response = HTTPURLResponse(url: URL(string: "http://example.com")!, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
                let endpointResolution: MoyaProvider<GitHub>.EndpointClosure = { target in
                    let url = target.baseURL.appendingPathComponent(target.path).absoluteString
                    return Endpoint(url: url, sampleResponseClosure: { .response(response, Data()) }, method: target.method, parameters: target.parameters)
                }
                let provider = MoyaProvider<GitHub>(endpointClosure: endpointResolution, stubClosure: MoyaProvider.immediatelyStub)

                var receivedResponse: URLResponse?
                provider.request(.zen) { result in
                    if case .success(let response) = result {
                        receivedResponse = response.response
                    }
                }

                expect(receivedResponse) === response
            }

            it("returns error") {
                let error = NSError(domain: "Internal iOS Error", code: -1234, userInfo: nil)
                let endpointResolution: MoyaProvider<GitHub>.EndpointClosure = { target in
                    let url = target.baseURL.appendingPathComponent(target.path).absoluteString
                    return Endpoint(url: url, sampleResponseClosure: { .networkError(error) }, method: target.method, parameters: target.parameters)
                }
                let provider = MoyaProvider<GitHub>(endpointClosure: endpointResolution, stubClosure: MoyaProvider.immediatelyStub)

                var receivedError: MoyaError?
                provider.request(.zen) { result in
                    if case .failure(let error) = result {
                        receivedError = error
                    }
                }

                if case .some(MoyaError.underlying(let underlyingError as NSError)) = receivedError {
                    expect(underlyingError) == error
                } else {
                    fail("Expected to receive error, did not.")
                }
            }
        }
        
        describe("a provider with error in request closure") {
            var provider: MoyaProvider<GitHub>!
            
            beforeEach {
                let endpointResolution: MoyaProvider<GitHub>.RequestClosure = { endpoint, done in
                    let underyingError = NSError(domain: "", code: 123, userInfo: nil)
                    done(.failure(.underlying(underyingError)))
                }
                provider = MoyaProvider<GitHub>(requestClosure: endpointResolution, stubClosure: MoyaProvider.immediatelyStub)
            }
            
            it("returns failure for any given request") {
                let target: GitHub = .zen
                var receivedError: MoyaError?
                provider.request(target) { response in
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
                provider = MoyaProvider(endpointClosure: failureEndpointClosure, stubClosure: MoyaProvider.immediatelyStub)
            }
            
            it("returns stubbed data for zen request") {
                var errored = false
                let target: GitHub = .zen

                waitUntil { done in
                    provider.request(target) { result in
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
                    provider.request(target) { result in
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
                var receivedError: MoyaError?
                
                let target: GitHub = .userProfile("ashfurrow")
                provider.request(target) { result in
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
                let baseURL = URL(string: "http://example.com")!
                let path = "/endpoint"
                let method = Moya.Method.get
                let parameters: [String: Any]? = ["key": "value"]
                let parameterEncoding: ParameterEncoding = URLEncoding.default
                let task = Task.request
                let sampleData = "sample data".data(using: .utf8)!
            }

            it("uses correct URL") {
                var requestedURL: String?
                let endpointResolution: MoyaProvider<MultiTarget>.RequestClosure = { endpoint, done in
                    requestedURL = endpoint.url
                    if let urlRequest = endpoint.urlRequest {
                        done(.success(urlRequest))
                    } else {
                        done(.failure(MoyaError.requestMapping(endpoint.url)))
                    }
                }
                let provider = MoyaProvider<MultiTarget>(requestClosure: endpointResolution, stubClosure: MoyaProvider.immediatelyStub)

                waitUntil { done in
                    provider.request(MultiTarget(StructAPI())) { _ in
                        done()
                    }
                }

                expect(requestedURL) == "http://example.com/endpoint"
            }

            it("uses correct parameters") {
                var requestParameters: [String: Any]?
                let endpointResolution: MoyaProvider<MultiTarget>.RequestClosure = { endpoint, done in
                    requestParameters = endpoint.parameters
                    if let urlRequest = endpoint.urlRequest {
                        done(.success(urlRequest))
                    } else {
                        done(.failure(MoyaError.requestMapping(endpoint.url)))
                    }
                }
                let provider = MoyaProvider<MultiTarget>(requestClosure: endpointResolution, stubClosure: MoyaProvider.immediatelyStub)

                waitUntil { done in
                    provider.request(MultiTarget(StructAPI())) { _ in
                        done()
                    }
                }

                expect(requestParameters?.count) == 1
            }

            it("uses correct method") {
                var requestMethod: Moya.Method?
                let endpointResolution: MoyaProvider<MultiTarget>.RequestClosure = { endpoint, done in
                    requestMethod = endpoint.method
                    if let urlRequest = endpoint.urlRequest {
                        done(.success(urlRequest))
                    } else {
                        done(.failure(MoyaError.requestMapping(endpoint.url)))
                    }
                }
                let provider = MoyaProvider<MultiTarget>(requestClosure: endpointResolution, stubClosure: MoyaProvider.immediatelyStub)

                waitUntil { done in
                    provider.request(MultiTarget(StructAPI())) { _ in
                        done()
                    }
                }

                expect(requestMethod) == .get
            }

            it("uses correct sample data") {
                var dataString: String?
                let provider = MoyaProvider<MultiTarget>(stubClosure: MoyaProvider.immediatelyStub)

                waitUntil { done in
                    provider.request(MultiTarget(StructAPI())) { result in
                        if case let .success(response) = result {
                            dataString = String(data: response.data, encoding: .utf8)
                        }
                        done()
                    }
                }

                expect(dataString) == "sample data"
            }
        }

        describe("a target with empty path") {
            struct PathlessAPI: TargetType {
                let baseURL = URL(string: "http://example.com/123/somepath?X-ABC-Asd=123")!
                let path = ""
                let method = Moya.Method.get
                let parameters: [String: Any]? = ["key": "value"]
                let parameterEncoding: ParameterEncoding = URLEncoding.default
                let task = Task.request
                let sampleData = "sample data".data(using: .utf8)!
            }

            // When a TargetType's path is empty, URL.appendingPathComponent may introduce trailing /, which may not be wanted in some cases
            // See: https://github.com/Moya/Moya/pull/1053
            // And: https://github.com/Moya/Moya/issues/1049
            it("uses the base url unchanged") {
                let endpoint = MoyaProvider.defaultEndpointMapping(for: PathlessAPI())
                expect(endpoint.url) == "http://example.com/123/somepath?X-ABC-Asd=123"
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
                
                provider.request(target) { result in
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
                provider = MoyaProvider<GitHub>(stubClosure: MoyaProvider.delayedStub(0.5))
            }
            
            it("invokes completion and returns .Failure if cancelled immediately") {
                var error: MoyaError?
                waitUntil { done in
                    let cancellable = provider.request(.zen, completion: { (result) in
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
        
        describe("a provider with progress tracking") {
            var provider: MoyaProvider<GitHubUserContent>!
            beforeEach {
                
                //delete downloaded filed before each test
                let directoryURLs = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
                let file = directoryURLs.first!.appendingPathComponent("logo_github.png")
                try? FileManager.default.removeItem(at: file)
                
                //`responseTime(-4)` equals to 1000 bytes at a time. The sample data is 4000 bytes.
                OHHTTPStubs.stubRequests(passingTest: {$0.url!.path.hasSuffix("logo_github.png")}) { _ in
                    return OHHTTPStubsResponse(data: GitHubUserContent.downloadMoyaWebContent("logo_github.png").sampleData, statusCode: 200, headers: nil).responseTime(-4)
                }
                provider = MoyaProvider<GitHubUserContent>()
            }
            
            it("tracks progress of request") {
                
                let target: GitHubUserContent = .downloadMoyaWebContent("logo_github.png")
                
                var progressValues: [Double] = []
                var completedValues: [Bool] = []
                var error: MoyaError?
                
                waitUntil(timeout: 5.0) { done in
                    let progressClosure: ProgressBlock = { progress in
                        progressValues.append(progress.progress)
                        completedValues.append(progress.completed)
                    }
                    
                    let progressCompletionClosure: Completion = { (result) in
                        if case .failure(let err) = result {
                            error = err
                        }
                        done()
                    }
                    
                    provider.request(target, queue: nil, progress: progressClosure, completion: progressCompletionClosure)
                }
                
                expect(error).to(beNil())
                expect(progressValues) == [0.25, 0.5, 0.75, 1.0, 1.0]
                expect(completedValues) == [false, false, false, false, true]
            }
        }
    }
}
