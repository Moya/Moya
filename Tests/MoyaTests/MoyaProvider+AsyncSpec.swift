#if swift(>=5.5)
import Quick
import Nimble
import AsyncMoya

#if canImport(OHHTTPStubs)
import OHHTTPStubs
#elseif canImport(OHHTTPStubsSwift)
import OHHTTPStubsCore
import OHHTTPStubsSwift
#endif

@testable import Moya
import XCTest

final class MoyaProviderAsyncSpec: QuickSpec {

    override func spec() {
        describe("provider") {
            let provider: MoyaProvider<GitHub> = MoyaProvider<GitHub>(stubClosure: MoyaProvider.immediatelyStub)

            it("one response object returned") {
                waitUntil { done in
                    AsyncTask {
                        var calls = 0

                        let result = await provider.request(.zen)

                        switch result {
                        case let .failure(error):
                            fail("errored: \(error)")
                        default:
                            ()
                        }

                        calls += 1
                        expect(calls).to(equal(1))
                        done()
                    }
                }
            }

            it("data for zen request") {
                waitUntil { done in
                    AsyncTask {
                        var responseData: Data?

                        let sampleTarget: GitHub = .zen
                        let result = await provider.request(sampleTarget)

                        switch result {
                        case let .failure(error):
                            fail("errored: \(error)")
                        case let .success(response):
                            responseData = response.data
                        }

                        expect(responseData).to(equal(sampleTarget.sampleData))
                        done()
                    }
                }
            }
        }

        describe("failing") {
            let provider: MoyaProvider<GitHub> = MoyaProvider<GitHub>(endpointClosure: failureEndpointClosure, stubClosure: MoyaProvider.immediatelyStub)

            it("emits the correct error message") {
                waitUntil { done in
                    AsyncTask {
                        var receivedError: MoyaError?

                        let result = await provider.request(.zen)

                        switch result {
                        case let .failure(error):
                            receivedError = error
                        case .success:
                            fail("should have errored")
                        }

                        switch receivedError {
                        case .some(.underlying(let error, _)):
                            expect(error.localizedDescription) == "Houston, we have a problem"
                        default:
                            fail("expected an Underlying error that Houston has a problem")
                        }
                        done()
                    }
                }
            }

            it("emits an error") {

                waitUntil { done in
                    AsyncTask {
                        var errored = false

                        let sampleTarget: GitHub = .zen
                        let result = await provider.request(sampleTarget)
                        switch result {
                        case .failure:
                            errored = true
                        case .success:
                            fail("should have errored")
                        }

                        expect(errored).to(beTrue())
                        done()
                    }
                }
            }
        }
    }

    func testProgressRequest() async {
        let directoryURLs = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let file = directoryURLs.first!.appendingPathComponent("logo_github.png")
        try? FileManager.default.removeItem(at: file)

        HTTPStubs.stubRequests(passingTest: {$0.url!.path.hasSuffix("logo_github.png")}, withStubResponse: { _ in
            return HTTPStubsResponse(data: GitHubUserContent.downloadMoyaWebContent("logo_github.png").sampleData, statusCode: 200, headers: nil).responseTime(-4)
        })
        let provider: MoyaProvider<GitHubUserContent> = MoyaProvider<GitHubUserContent>()
        let sampleTarget: GitHubUserContent = .downloadMoyaWebContent("logo_github.png")

        let expectedNextProgressValues = [0.25, 0.5, 0.75, 1.0, 1.0]
        let expectedNextResponseCount = 1
        let expectedErrorEventsCount = 0
        let expectedCompletedEventsCount = 1

        var nextProgressValues: [Double] = []
        var nextResponseCount = 0
        var errorEventsCount = 0
        var completedEventsCount = 0

        for await progressResponse in await provider.requestWithProgress(sampleTarget) {
            switch progressResponse {
            case let .success(response):
                nextProgressValues.append(response.progress)
                if response.response != nil { nextResponseCount += 1 }
            case .failure:
                errorEventsCount += 1
            }
        }
        completedEventsCount += 1

        XCTAssertEqual(completedEventsCount, expectedCompletedEventsCount)
        XCTAssertEqual(errorEventsCount, expectedErrorEventsCount)
        XCTAssertEqual(nextResponseCount, expectedNextResponseCount)
        XCTAssertEqual(nextProgressValues, expectedNextProgressValues)
    }
}

#endif
