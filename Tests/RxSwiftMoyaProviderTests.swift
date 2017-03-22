import Quick
import Nimble
import RxSwift
import Alamofire
import OHHTTPStubs

@testable import Moya
@testable import RxMoya

class RxSwiftMoyaProviderSpec: QuickSpec {
    override func spec() {

        describe("provider with Single") {

            var provider: RxMoyaProvider<GitHub>!

            beforeEach {
                provider = RxMoyaProvider(stubClosure: MoyaProvider.immediatelyStub)
            }

            it("emits a Response object") {
                var called = false

                _ = provider.request(.zen).subscribe { event in
                    switch event {
                    case .success:          called = true
                    case .error(let error): fail("errored: \(error)")
                    }
                }

                expect(called).to(beTrue())
            }

            it("emits stubbed data for zen request") {
                var responseData: Data?

                let target: GitHub = .zen
                _ = provider.request(target).subscribe { event in
                    switch event {
                    case .success(let response):    responseData = response.data
                    case .error(let error):         fail("errored: \(error)")
                    }
                }

                expect(responseData).to(equal(target.sampleData))
            }

            it("maps JSON data correctly for user profile request") {
                var receivedResponse: [String: Any]?

                let target: GitHub = .userProfile("ashfurrow")
                _ = provider.request(target).asObservable().mapJSON().subscribe(onNext: { response in
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

                _ = provider.request(.zen).subscribe { event in
                    switch event {
                    case .success:          fail("should have errored")
                    case .error(let error): receivedError = error as? MoyaError
                    }
                }

                switch receivedError {
                case .some(.underlying(let error, _)):
                    expect(error.localizedDescription) == "Houston, we have a problem"
                default:
                    fail("expected an Underlying error that Houston has a problem")
                }
            }

            it("emits an error") {
                var errored = false

                let target: GitHub = .zen
                _ = provider.request(target).subscribe { event in
                    switch event {
                    case .success:  fail("we should have errored")
                    case .error:    errored = true
                    }
                }

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
                let signalProducer1 = provider.request(target)
                let signalProducer2 = provider.request(target)

                expect(provider.inflightRequests.keys.count).to(equal(0))

                var receivedResponse: Moya.Response!

                _ = signalProducer1.subscribe { event in
                    switch event {
                    case .success(let response):
                        receivedResponse = response
                        expect(provider.inflightRequests.count).to(equal(1))

                    case .error(let error):
                        fail("errored: \(error)")
                    }
                }

                _ = signalProducer2.subscribe { event in
                    switch event {
                    case .success(let response):
                        expect(receivedResponse).toNot(beNil())
                        expect(receivedResponse).to(beIdenticalToResponse(response))
                        expect(provider.inflightRequests.count).to(equal(1))

                    case .error(let error):
                        fail("errored: \(error)")
                    }
                }

                // Allow for network request to complete
                expect(provider.inflightRequests.count).toEventually(equal(0))
            }
        }
    }
}
