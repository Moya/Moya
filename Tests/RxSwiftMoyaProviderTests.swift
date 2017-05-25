import Quick
import Nimble
import RxSwift
import Alamofire
import OHHTTPStubs

@testable import Moya
@testable import RxMoya

class RxSwiftMoyaProviderSpec: QuickSpec {
    override func spec() {

        describe("provider with Observable") {

            var provider: RxMoyaProvider<GitHub>!

            beforeEach {
                provider = RxMoyaProvider(stubClosure: MoyaProvider.immediatelyStub)
            }

            it("emits a Response object") {
                var called = false

                _ = provider.request(.zen).subscribe(onNext: { _ in
                    called = true
                })

                expect(called).to(beTrue())
            }

            it("emits complete") {
                var complete = false

                _ = provider.request(.zen).subscribe(onCompleted: { _ in
                    complete = true
                })

                expect(complete).to(beTrue())
            }

            it("emits stubbed data for zen request") {
                var responseData: Data?

                let target: GitHub = .zen
                _ = provider.request(target).subscribe(onNext: { response in
                    responseData = response.data
                })

                expect(responseData).to(equal(target.sampleData))
            }

            it("maps JSON data correctly for user profile request") {
                var receivedResponse: [String: Any]?

                let target: GitHub = .userProfile("ashfurrow")
                _ = provider.request(target).mapJSON().subscribe(onNext: { response in
                    receivedResponse = response as? [String: Any]
                })

                expect(receivedResponse).toNot(beNil())
            }
        }

        describe("failing") {
            var provider: RxMoyaProvider<GitHub>!
            beforeEach {
                provider = RxMoyaProvider<GitHub>(endpointClosure: failureEndpointClosure, stubClosure: MoyaProvider.immediatelyStub)
            }

            it("emits the correct error message") {
                var receivedError: MoyaError?

                _ = provider.request(.zen).subscribe(onError: { error in
                    receivedError = error as? MoyaError
                })

                switch receivedError {
                case .some(.underlying(let error)):
                    expect(error.localizedDescription) == "Houston, we have a problem"
                default:
                    fail("expected an Underlying error that Houston has a problem")
                }
            }

            it("emits an error") {
                var errored = false

                let target: GitHub = .zen
                _ = provider.request(target).subscribe(onError: { _ in
                    errored = true
                })

                expect(errored).to(beTrue())
            }
        }

        describe("a reactive provider") {
            var provider: RxMoyaProvider<GitHub>!
            beforeEach {
                OHHTTPStubs.stubRequests(passingTest: {$0.url!.path == "/zen"}) { _ in
                    return OHHTTPStubsResponse(data: GitHub.zen.sampleData, statusCode: 200, headers: nil)
                }
                provider = RxMoyaProvider<GitHub>(trackInflights: true)
            }

            it("emits identical response for inflight requests") {
                let target: GitHub = .zen
                let signalProducer1: Observable<Moya.Response> = provider.request(target)
                let signalProducer2: Observable<Moya.Response> = provider.request(target)

                expect(provider.inflightRequests.keys.count).to(equal(0))

                var receivedResponse: Moya.Response!

                _ = signalProducer1.subscribe(onNext: { response in
                    receivedResponse = response
                    expect(provider.inflightRequests.count).to(equal(1))
                })

                _ = signalProducer2.subscribe(onNext: { response in
                    expect(receivedResponse).toNot(beNil())
                    expect(receivedResponse).to(beIdenticalToResponse(response))
                    expect(provider.inflightRequests.count).to(equal(1))
                })

                // Allow for network request to complete
                expect(provider.inflightRequests.count).toEventually(equal(0))
            }
        }

        describe("a provider with progress tracking") {
            var provider: RxMoyaProvider<GitHubUserContent>!
            beforeEach {
                //delete downloaded filed before each test
                let directoryURLs = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
                let file = directoryURLs.first!.appendingPathComponent("logo_github.png")
                try? FileManager.default.removeItem(at: file)

                //`responseTime(-4)` equals to 1000 bytes at a time. The sample data is 4000 bytes.
                OHHTTPStubs.stubRequests(passingTest: {$0.url!.path.hasSuffix("logo_github.png")}) { _ in
                    return OHHTTPStubsResponse(data: GitHubUserContent.downloadMoyaWebContent("logo_github.png").sampleData, statusCode: 200, headers: nil).responseTime(-4)
                }
                provider = RxMoyaProvider<GitHubUserContent>()
            }

            it("tracks progress of request") {
                let target: GitHubUserContent = .downloadMoyaWebContent("logo_github.png")

                let expectedNextProgressValues = [0.25, 0.5, 0.75, 1.0, 1.0]
                let expectedNextResponseCount = 1
                let expectedErrorEventsCount = 0
                let expectedCompletedEventsCount = 1
                let timeout = 5.0

                var nextProgressValues: [Double] = []
                var nextResponseCount = 0
                var errorEventsCount = 0
                var completedEventsCount = 0

                _ = provider.requestWithProgress(target)
                    .subscribe({ event in
                        switch event {
                        case let .next(element):
                            nextProgressValues.append(element.progress)

                            if let _ = element.response { nextResponseCount += 1 }
                        case .error: errorEventsCount += 1
                        case .completed: completedEventsCount += 1
                        }
                    })

                expect(completedEventsCount).toEventually(equal(expectedCompletedEventsCount), timeout: timeout)
                expect(errorEventsCount).toEventually(equal(expectedErrorEventsCount), timeout: timeout)
                expect(nextResponseCount).toEventually(equal(expectedNextResponseCount), timeout: timeout)
                expect(nextProgressValues).toEventually(equal(expectedNextProgressValues), timeout: timeout)
            }
        }
    }
}
