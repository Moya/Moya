// swiftlint:disable file_length type_body_length

import Quick
import Nimble
import Foundation
import OHHTTPStubs
@testable import Moya

final class MoyaProviderSpec: QuickSpec {
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
            let urlRequest1 = try? endpoint1.urlRequest()
            let urlRequest2 = try? endpoint2.urlRequest()
            expect(urlRequest1).toNot(beNil())
            expect(urlRequest1).to(equal(urlRequest2))
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
            let plugin = CredentialsPlugin { (_) -> URLCredential? in
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
            let plugin = CredentialsPlugin { (_) -> URLCredential? in
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
            var calledTarget: GitHub?

            let plugin = NetworkActivityPlugin { change, target in
                if change == .began {
                    called = true
                    calledTarget = target as? GitHub
                }
            }

            let provider = MoyaProvider<GitHub>(stubClosure: MoyaProvider.immediatelyStub, plugins: [plugin])
            let target: GitHub = .zen
            provider.request(target) { _ in  }

            expect(called) == true
            expect(calledTarget) == target
        }

        it("notifies at the end of network requests") {
            var called = false
            var calledTarget: GitHub?

            let plugin = NetworkActivityPlugin { change, target in
                if change == .ended {
                    called = true
                    calledTarget = target as? GitHub
                }
            }

            let provider = MoyaProvider<GitHub>(stubClosure: MoyaProvider.immediatelyStub, plugins: [plugin])
            let target: GitHub = .zen
            provider.request(target) { _ in  }

            expect(called) == true
            expect(calledTarget) == target
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

            it("returns an error when request is canceled") {
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

            it("notifies plugins when request is canceled") {
                var receivedError: Swift.Error?

                waitUntil { done in
                    let target: GitHub = .userProfile("ashfurrow")
                    let token = provider.request(target) { _ in
                        done()
                    }
                    token.cancel()
                }

                if let result = plugin.result,
                    case let .failure(error) = result {
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

            it("returns success when request is not canceled") {
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

            func delay(_ delay: TimeInterval, block: @escaping () -> Void) {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: block)
            }

            beforeEach {
                let endpointResolution: MoyaProvider<GitHub>.RequestClosure = { endpoint, done in
                    delay(requestTime) {
                        do {
                            let urlRequest = try endpoint.urlRequest()
                            done(.success(urlRequest))
                        } catch MoyaError.requestMapping(let url) {
                            done(.failure(MoyaError.requestMapping(url)))
                        } catch {
                            done(.failure(MoyaError.parameterEncoding(error)))
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

            it("calls completion if canceled immediately") {
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

            it("calls completion if canceled before request is created") {
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

            it("receives an error if request is canceled before response comes back") {
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
                    do {
                        let urlRequest = try endpoint.urlRequest()
                        done(.success(urlRequest))
                    } catch MoyaError.requestMapping(let url) {
                        done(.failure(MoyaError.requestMapping(url)))
                    } catch {
                        done(.failure(MoyaError.parameterEncoding(error)))
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
                    return Endpoint(url: url, sampleResponseClosure: {.networkResponse(200, target.sampleData)}, method: target.method, task: target.task, httpHeaderFields: target.headers)
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
                let response = HTTPURLResponse(url: URL(string: "http://example.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                let endpointResolution: MoyaProvider<GitHub>.EndpointClosure = { target in
                    return Endpoint(url: URL(target: target).absoluteString, sampleResponseClosure: { .response(response, target.sampleData) }, method: target.method, task: target.task, httpHeaderFields: target.headers)
                }
                let provider = MoyaProvider<GitHub>(endpointClosure: endpointResolution, stubClosure: MoyaProvider.immediatelyStub)

                var receivedResponse: HTTPURLResponse?
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
                    return Endpoint(url: url, sampleResponseClosure: { .networkError(error) }, method: target.method, task: target.task, httpHeaderFields: target.headers)
                }
                let provider = MoyaProvider<GitHub>(endpointClosure: endpointResolution, stubClosure: MoyaProvider.immediatelyStub)

                var receivedError: MoyaError?
                provider.request(.zen) { result in
                    if case .failure(let error) = result {
                        receivedError = error
                    }
                }

                if case .some(MoyaError.underlying(let underlyingError as NSError, _)) = receivedError {
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
                    done(.failure(.underlying(underyingError, nil)))
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

        describe("a provider with stubbed errors") {
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

                _ = target.sampleData
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

                _ = target.sampleData
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
                case .some(.underlying(let error, _)):
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
                let task = Task.requestParameters(parameters: ["key": "value"], encoding: URLEncoding.default)
                let sampleData = "sample data".data(using: .utf8)!
                let headers: [String: String]? = ["headerKey": "headerValue"]
            }

            it("uses correct URL") {
                var requestedURL: String?
                let endpointResolution: MoyaProvider<MultiTarget>.RequestClosure = { endpoint, done in
                    requestedURL = endpoint.url
                    do {
                        let urlRequest = try endpoint.urlRequest()
                        done(.success(urlRequest))
                    } catch MoyaError.requestMapping(let url) {
                        done(.failure(MoyaError.requestMapping(url)))
                    } catch {
                        done(.failure(MoyaError.parameterEncoding(error)))
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

            it("uses correct method") {
                var requestMethod: Moya.Method?
                let endpointResolution: MoyaProvider<MultiTarget>.RequestClosure = { endpoint, done in
                    requestMethod = endpoint.method
                    do {
                        let urlRequest = try endpoint.urlRequest()
                        done(.success(urlRequest))
                    } catch MoyaError.requestMapping(let url) {
                        done(.failure(MoyaError.requestMapping(url)))
                    } catch {
                        done(.failure(MoyaError.parameterEncoding(error)))
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

                expect(dataString).to(equal("sample data"))
            }

            it("uses correct headers") {
                var headers: [String: String]?
                let endpointResolution: MoyaProvider<MultiTarget>.RequestClosure = { endpoint, done in
                    headers = endpoint.httpHeaderFields
                    do {
                        let urlRequest = try endpoint.urlRequest()
                        done(.success(urlRequest))
                    } catch MoyaError.requestMapping(let url) {
                        done(.failure(MoyaError.requestMapping(url)))
                    } catch {
                        done(.failure(MoyaError.parameterEncoding(error)))
                    }
                }
                let provider = MoyaProvider<MultiTarget>(requestClosure: endpointResolution, stubClosure: MoyaProvider.immediatelyStub)

                waitUntil { done in
                    provider.request(MultiTarget(StructAPI())) { _ in
                        done()
                    }
                }

                expect(headers) == ["headerKey": "headerValue"]
            }
        }

        describe("a target with empty path") {
            struct PathlessAPI: TargetType {
                let baseURL = URL(string: "http://example.com/123/somepath?X-ABC-Asd=123")!
                let path = ""
                let method = Moya.Method.get
                let task = Task.requestParameters(parameters: ["key": "value"], encoding: URLEncoding.default)
                let sampleData = "sample data".data(using: .utf8)!
                let headers: [String: String]? = nil
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
                OHHTTPStubs.stubRequests(passingTest: {$0.url!.path == "/zen"}, withStubResponse: { _ in
                    return OHHTTPStubsResponse(data: GitHub.zen.sampleData, statusCode: 200, headers: nil)
                })
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
            beforeEach {
                provider = MoyaProvider<GitHub>(stubClosure: MoyaProvider.delayedStub(0.5))
            }

            it("invokes completion and returns. Failure if canceled immediately") {
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
                if let error = error, case .underlying(let err, _) = error {
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
                OHHTTPStubs.stubRequests(passingTest: {$0.url!.path.hasSuffix("logo_github.png")}, withStubResponse: { _ in
                    return OHHTTPStubsResponse(data: GitHubUserContent.downloadMoyaWebContent("logo_github.png").sampleData, statusCode: 200, headers: nil).responseTime(-4)
                })
                provider = MoyaProvider<GitHubUserContent>()
            }

            it("tracks progress of download request") {

                let target: GitHubUserContent = .downloadMoyaWebContent("logo_github.png")

                var progressObjects: [Progress?] = []
                var progressValues: [Double] = []
                var completedValues: [Bool] = []
                var error: MoyaError?

                waitUntil(timeout: 5.0) { done in
                    let progressClosure: ProgressBlock = { progress in
                        progressObjects.append(progress.progressObject)
                        progressValues.append(progress.progress)
                        completedValues.append(progress.completed)
                    }

                    let progressCompletionClosure: Completion = { (result) in
                        if case .failure(let err) = result {
                            error = err
                        }
                        done()
                    }

                    provider.request(target, callbackQueue: nil, progress: progressClosure, completion: progressCompletionClosure)
                }

                expect(error).to(beNil())
                expect(progressValues) == [0.25, 0.5, 0.75, 1.0, 1.0]
                expect(completedValues) == [false, false, false, false, true]
                expect(progressObjects.filter { $0 != nil }.count) == 5
            }

            it("tracks progress of request") {

                let target: GitHubUserContent = .requestMoyaWebContent("logo_github.png")

                var progressObjects: [Progress?] = []
                var progressValues: [Double] = []
                var completedValues: [Bool] = []
                var error: MoyaError?

                waitUntil(timeout: 5.0) { done in
                    let progressClosure: ProgressBlock = { progress in
                        progressObjects.append(progress.progressObject)
                        progressValues.append(progress.progress)
                        completedValues.append(progress.completed)
                    }

                    let progressCompletionClosure: Completion = { (result) in
                        if case .failure(let err) = result {
                            error = err
                        }
                        done()
                    }

                    provider.request(target, callbackQueue: nil, progress: progressClosure, completion: progressCompletionClosure)
                }

                expect(error).to(beNil())
                expect(progressValues) == [0.25, 0.5, 0.75, 1.0, 1.0]
                expect(completedValues) == [false, false, false, false, true]
                expect(progressObjects.filter { $0 != nil }.count) == 5
            }

        }

        describe("a provider with upload progress tracking") {
            var provider: MoyaProvider<HTTPBin>!
            beforeEach {
                provider = MoyaProvider<HTTPBin>()
            }

            it("tracks progress of request") {

                let url = Bundle(for: MoyaProviderSpec.self).url(forResource: "testImage", withExtension: "png")!
                let target: HTTPBin = .upload(file: url)

                var progressObjects: [Progress?] = []
                var progressValues: [Double] = []
                var completedValues: [Bool] = []
                var error: MoyaError?

                waitUntil(timeout: 5.0) { done in
                    let progressClosure: ProgressBlock = { progress in
                        progressObjects.append(progress.progressObject)
                        progressValues.append(progress.progress)
                        completedValues.append(progress.completed)
                    }

                    let progressCompletionClosure: Completion = { (result) in
                        if case .failure(let err) = result {
                            error = err
                        }
                        done()
                    }

                    provider.request(target, callbackQueue: nil, progress: progressClosure, completion: progressCompletionClosure)
                }

                expect(error).to(beNil())
                expect(progressValues.count) > 3
                expect(completedValues.count) > 3
                expect(completedValues.filter { !$0 }.count) == completedValues.count - 1 // only false except one
                expect(completedValues.last) == true // the last must be true
                expect(progressObjects.filter { $0 != nil }.count) == progressObjects.count // no nil object
            }

            it("tracks progress of multipart request") {

                let formData = HTTPBin.createTestMultipartFormData()
                let target = HTTPBin.uploadMultipart(formData, nil)

                var progressObjects: [Progress?] = []
                var progressValues: [Double] = []
                var completedValues: [Bool] = []
                var error: MoyaError?

                waitUntil(timeout: 5.0) { done in
                    let progressClosure: ProgressBlock = { progress in
                        progressObjects.append(progress.progressObject)
                        progressValues.append(progress.progress)
                        completedValues.append(progress.completed)
                    }

                    let progressCompletionClosure: Completion = { (result) in
                        if case .failure(let err) = result {
                            error = err
                        }
                        done()
                    }

                    provider.request(target, callbackQueue: nil, progress: progressClosure, completion: progressCompletionClosure)
                }

                expect(error).to(beNil())
                expect(progressValues.count) > 3
                expect(completedValues.count) > 3
                expect(completedValues.filter { !$0 }.count) == completedValues.count - 1 // only false except one
                expect(completedValues.last) == true // the last must be true
                expect(progressObjects.filter { $0 != nil }.count) == progressObjects.count // no nil object
            }
        }

        describe("using a custom callback queue") {
            var stubDescriptor: OHHTTPStubsDescriptor!

            beforeEach {
                stubDescriptor = OHHTTPStubs.stubRequests(passingTest: {$0.url!.path == "/zen"}, withStubResponse: { _ in
                    return OHHTTPStubsResponse(data: GitHub.zen.sampleData, statusCode: 200, headers: nil)
                })
            }

            afterEach {
                OHHTTPStubs.removeStub(stubDescriptor)
            }

            describe("a provider with a predefined callback queue") {
                var provider: MoyaProvider<GitHub>!
                var callbackQueue: DispatchQueue!

                beforeEach {
                    callbackQueue = DispatchQueue(label: UUID().uuidString)
                    provider = MoyaProvider<GitHub>(callbackQueue: callbackQueue)
                }

                context("a provider is given a callback queue with request") {
                    it("invokes the callback on the request queue") {
                        let requestQueue = DispatchQueue(label: UUID().uuidString)
                        var callbackQueueLabel: String?

                        waitUntil(action: { completion in
                            provider.request(.zen, callbackQueue: requestQueue) { _ in
                                callbackQueueLabel = DispatchQueue.currentLabel
                                completion()
                            }
                        })

                        expect(callbackQueueLabel) == requestQueue.label
                    }
                }

                context("a provider uses the queueless request function") {
                    it("invokes the callback on the provider queue") {
                        var callbackQueueLabel: String?

                        waitUntil(action: { completion in
                            provider.request(.zen) { _ in
                                callbackQueueLabel = DispatchQueue.currentLabel
                                completion()
                            }
                        })

                        expect(callbackQueueLabel) == callbackQueue.label
                    }
                }
            }

            describe("a provider without a predefined callback queue") {
                var provider: MoyaProvider<GitHub>!

                beforeEach {
                    provider = MoyaProvider<GitHub>()
                }

                context("where the callback queue is provided with request") {
                    it("invokes the callback on the request queue") {
                        let requestQueue = DispatchQueue(label: UUID().uuidString)
                        var callbackQueueLabel: String?

                        waitUntil(action: { completion in
                            provider.request(.zen, callbackQueue: requestQueue) { _ in
                                callbackQueueLabel = DispatchQueue.currentLabel
                                completion()
                            }
                        })

                        expect(callbackQueueLabel) == requestQueue.label
                    }
                }

                context("where the queueless request method is invoked") {
                    it("invokes the callback on the main queue") {
                        var callbackQueueLabel: String?

                        waitUntil(action: { completion in
                            provider.request(.zen) { _ in
                                callbackQueueLabel = DispatchQueue.currentLabel
                                completion()
                            }
                        })

                        expect(callbackQueueLabel) == DispatchQueue.main.label
                    }
                }
            }
        }

        // Resolves #1592 where validation is not performed on a stubbed request
        describe("a provider for stubbed requests with validation") {
            var stubbedProvider: MoyaProvider<GitHub>!

            context("response contains invalid status code") {
                it("returns an error") {
                    let endpointClosure = { (target: GitHub) -> Endpoint in
                        return Endpoint(
                            url: URL(target: target).absoluteString,
                            sampleResponseClosure: { .networkResponse(400, target.sampleData) },
                            method: target.method,
                            task: target.task,
                            httpHeaderFields: target.headers
                        )
                    }

                    stubbedProvider = MoyaProvider<GitHub>(endpointClosure: endpointClosure, stubClosure: MoyaProvider.immediatelyStub)

                    var receivedError: Error?
                    var receivedResponse: Response?

                    waitUntil { done in
                        stubbedProvider.request(.zen) { result in
                            switch result {
                            case .success(let response):
                                receivedResponse = response
                            case .failure(let error):
                                receivedError = error
                            }
                            done()
                        }
                    }

                    expect(receivedResponse).to(beNil())
                    expect(receivedError).toNot(beNil())
                }
            }

            context("response contains valid status code") {
                it("returns a response") {
                    let endpointClosure = { (target: GitHub) -> Endpoint in
                        return Endpoint(
                            url: URL(target: target).absoluteString,
                            sampleResponseClosure: { .networkResponse(200, target.sampleData) },
                            method: target.method,
                            task: target.task,
                            httpHeaderFields: target.headers
                        )
                    }

                    stubbedProvider = MoyaProvider<GitHub>(endpointClosure: endpointClosure, stubClosure: MoyaProvider.immediatelyStub)

                    var receivedError: Error?
                    var receivedResponse: Response?

                    waitUntil { done in
                        stubbedProvider.request(.zen) { result in
                            switch result {
                            case .success(let response):
                                receivedResponse = response
                            case .failure(let error):
                                receivedError = error
                            }
                            done()
                        }
                    }

                    expect(receivedResponse).toNot(beNil())
                    expect(receivedError).to(beNil())
                    expect(GitHub.zen.validationType.statusCodes).to(contain(receivedResponse!.statusCode))
                }
            }
        }
    }
}
