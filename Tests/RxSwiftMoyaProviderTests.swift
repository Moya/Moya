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
                let signalProducer1:Observable<Moya.Response> = provider.request(target)
                let signalProducer2:Observable<Moya.Response> = provider.request(target)

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
        
        describe("a custom callback queue") {
            var stubDescriptor: OHHTTPStubsDescriptor!
            
            beforeEach {
                stubDescriptor = OHHTTPStubs.stubRequests(passingTest: {$0.url!.path == "/zen"}) { _ in
                    return OHHTTPStubsResponse(data: GitHub.zen.sampleData, statusCode: 200, headers: nil)
                }
            }
            
            afterEach {
                OHHTTPStubs.removeStub(stubDescriptor)
            }
            
            describe("a provider with predefined queue") {
                var provider: RxMoyaProvider<GitHub>!
                var queue: DispatchQueue!
                var disposeBag: DisposeBag!
                
                beforeEach {
                    disposeBag = DisposeBag()
                    
                    queue = DispatchQueue(label: UUID().uuidString)
                    provider = RxMoyaProvider<GitHub>(queue: queue)
                }
                
                context("the queue is provided with the request") {
                    it("invokes the callback on request queue") {
                        let requestQueue = DispatchQueue(label: UUID().uuidString)
                        var callbackQueueLabel: String?
                        
                        waitUntil(action: { completion in
                            provider.request(.zen, queue: requestQueue)
                            .subscribe(onNext: { _ in
                                callbackQueueLabel = DispatchQueue.currentLabel
                                completion()
                            }).addDisposableTo(disposeBag)
                        })
                        
                        expect(callbackQueueLabel) == requestQueue.label
                    }
                }
                
                context("the queueless request method is invoked") {
                    it("invokes the callback on provider queue", closure: {
                        var callbackQueueLabel: String?
                        
                        waitUntil(action: { completion in
                            provider.request(.zen)
                            .subscribe(onNext: { _ in
                                callbackQueueLabel = DispatchQueue.currentLabel
                                completion()
                            }).addDisposableTo(disposeBag)
                        })
                        
                        expect(callbackQueueLabel) == queue.label
                    }
                }
            }
            
            describe("a provider without predefined queue") {
                var provider: RxMoyaProvider<GitHub>!
                var disposeBag: DisposeBag!
                
                beforeEach {
                    disposeBag = DisposeBag()
                    provider = RxMoyaProvider<GitHub>()
                }
                
                context("the queue is provided with request") {
                    it("invokes the callback on the specified queue") {
                        let requestQueue = DispatchQueue(label: UUID().uuidString)
                        var callbackQueueLabel: String?
                        
                        waitUntil(action: { completion in
                            provider.request(.zen, queue: requestQueue)
                            .subscribe(onNext: { _ in
                                callbackQueueLabel = DispatchQueue.currentLabel
                                completion()
                            }).addDisposableTo(disposeBag)
                        })
                        
                        expect(callbackQueueLabel) == requestQueue.label
                    }
                }
                
                context("the queue is not provided with request") {
                    it("invokes the callback on main queue") {
                        var callbackQueueLabel: String?
                        
                        waitUntil(action: { completion in
                            provider.request(.zen)
                            .subscribe(onNext: { _ in
                                callbackQueueLabel = DispatchQueue.currentLabel
                                completion()
                            }).addDisposableTo(disposeBag)
                        })
                        
                        expect(callbackQueueLabel) == DispatchQueue.main.label
                    }
                }
            })
        }
    }
}
