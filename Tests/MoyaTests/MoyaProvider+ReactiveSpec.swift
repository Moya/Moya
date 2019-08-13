import Quick
import Nimble
import ReactiveSwift

#if canImport(OHHTTPStubs)
import OHHTTPStubs
#elseif canImport(OHHTTPStubsSwift)
import OHHTTPStubsCore
import OHHTTPStubsSwift
#endif

@testable import Moya
@testable import ReactiveMoya

final class MoyaProviderReactiveSpec: QuickSpec {
    override func spec() {
        describe("failing") {
            var provider: MoyaProvider<GitHub>!

            beforeEach {
                provider = MoyaProvider<GitHub>(endpointClosure: failureEndpointClosure, stubClosure: MoyaProvider.immediatelyStub)
            }

            it("returns the correct error message") {
                var receivedError: MoyaError?

                waitUntil { done in
                    provider.reactive.request(.zen).startWithFailed { error in
                        receivedError = error
                        done()
                    }
                }

                switch receivedError {
                case .some(.underlying(let error, _)):
                    expect(error.localizedDescription) == "Houston, we have a problem"
                default:
                    fail("expected an Underlying error that Houston has a problem")
                }
            }

            it("returns an error") {
                var errored = false

                let target: GitHub = .zen
                provider.reactive.request(target).startWithFailed { _ in
                    errored = true
                }

                expect(errored).to(beTruthy())
            }
        }

        describe("provider with SignalProducer") {
            var provider: MoyaProvider<GitHub>!

            beforeEach {
                provider = MoyaProvider<GitHub>(stubClosure: MoyaProvider.immediatelyStub)
            }

            it("returns a Response object") {
                var called = false

                provider.reactive.request(.zen).startWithResult { _ in
                    called = true
                }

                expect(called).to(beTruthy())
            }

            it("returns stubbed data for zen request") {
                var message: String?

                let target: GitHub = .zen
                provider.reactive.request(target).startWithResult { result in
                    if case .success(let response) = result {
                        message = String(data: response.data, encoding: .utf8)
                    }
                }

                let sampleString = String(data: target.sampleData, encoding: .utf8)
                expect(message!).to(equal(sampleString))
            }

            it("returns correct data for user profile request") {
                var receivedResponse: NSDictionary?

                let target: GitHub = .userProfile("ashfurrow")
                provider.reactive.request(target).startWithResult { result in
                    if case .success(let response) = result {
                        receivedResponse = try! JSONSerialization.jsonObject(with: response.data, options: []) as? NSDictionary
                    }
                }

                let sampleData = target.sampleData
                let sampleResponse = try! JSONSerialization.jsonObject(with: sampleData, options: []) as! NSDictionary
                expect(receivedResponse).toNot(beNil())
                expect(receivedResponse) == sampleResponse
            }

        }

        describe("provider with inflight tracking") {
            var provider: MoyaProvider<GitHub>!
            beforeEach {
                OHHTTPStubs.stubRequests(passingTest: {$0.url!.path == "/zen"}, withStubResponse: { _ in
                    return OHHTTPStubsResponse(data: GitHub.zen.sampleData, statusCode: 200, headers: nil)
                })
                provider = MoyaProvider<GitHub>(trackInflights: true)
            }

            it("returns identical signalproducers for inflight requests") {
                let target: GitHub = .zen
                let signalProducer1: SignalProducer<Moya.Response, MoyaError> = provider.reactive.request(target)
                let signalProducer2: SignalProducer<Moya.Response, MoyaError> = provider.reactive.request(target)

                expect(provider.inflightRequests.keys.count).to( equal(0) )

                var receivedResponse: Moya.Response!

                signalProducer1.startWithResult { result in
                    if case .success(let response) = result {
                        receivedResponse = response
                        expect(provider.inflightRequests.count).to( equal(1) )
                    }
                }

                signalProducer2.startWithResult { result in
                    if case .success(let response) = result {
                        expect(receivedResponse).toNot( beNil() )
                        expect(receivedResponse).to( beIdenticalToResponse(response) )
                        expect(provider.inflightRequests.count).to( equal(1) )
                    }
                }

                // Allow for network request to complete
                expect(provider.inflightRequests.count).toEventually( equal(0) )
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

            it("tracks progress of request") {
                let target: GitHubUserContent = .downloadMoyaWebContent("logo_github.png")

                let expectedNextProgressValues = [0.25, 0.5, 0.75, 1.0, 1.0]
                let expectedNextResponseCount = 1
                let expectedFailedEventsCount = 0
                let expectedInterruptedEventsCount = 0
                let expectedCompletedEventsCount = 1
                let timeout = 5.0

                var nextProgressValues: [Double] = []
                var nextResponseCount = 0
                var failedEventsCount = 0
                var interruptedEventsCount = 0
                var completedEventsCount = 0

                _ = provider.reactive.requestWithProgress(target)
                    .start({ event in
                        switch event {
                        case let .value(element):
                            nextProgressValues.append(element.progress)

                            if element.response != nil { nextResponseCount += 1 }
                        case .failed: failedEventsCount += 1
                        case .completed: completedEventsCount += 1
                        case .interrupted: interruptedEventsCount += 1
                        }
                    })

                expect(completedEventsCount).toEventually(equal(expectedCompletedEventsCount), timeout: timeout)
                expect(failedEventsCount).toEventually(equal(expectedFailedEventsCount), timeout: timeout)
                expect(interruptedEventsCount).toEventually(equal(expectedInterruptedEventsCount), timeout: timeout)
                expect(nextResponseCount).toEventually(equal(expectedNextResponseCount), timeout: timeout)
                expect(nextProgressValues).toEventually(equal(expectedNextProgressValues), timeout: timeout)
            }
        }
    }
}
