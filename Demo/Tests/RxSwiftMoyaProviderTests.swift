import Quick
import Nimble
import Moya
import RxSwift
import Alamofire
import OHHTTPStubs

class RxSwiftMoyaProviderSpec: QuickSpec {
    override func spec() {
        
        describe("provider with Observable") {
            
            var provider: RxMoyaProvider<GitHub>!
            
            beforeEach {
                provider = RxMoyaProvider(stubClosure: MoyaProvider.immediatelyStub)
            }
            
            it("returns a Response object") {
                var called = false
                
                _ = provider.request(.zen).subscribe(onNext: { object in
                    called = true
                })
                
                expect(called).to(beTruthy())
            }
            
            it("returns stubbed data for zen request") {
                var message: String?
                
                let target: GitHub = .zen
                _ = provider.request(target).subscribe(onNext: { response in
                    message = String(data: response.data, encoding: .utf8)
                })
                
                let sampleString = String(data: target.sampleData, encoding: .utf8)
                expect(message).to(equal(sampleString))
            }
            
            it("returns correct data for user profile request") {
                var receivedResponse: NSDictionary?
                
                let target: GitHub = .userProfile("ashfurrow")
                _ = provider.request(target).subscribe(onNext: { response in
                    receivedResponse = try! JSONSerialization.jsonObject(with: response.data, options: []) as? NSDictionary
                })
                
                expect(receivedResponse).toNot(beNil())
            }
        }
        
        describe("failing") {
            var provider: RxMoyaProvider<GitHub>!
            beforeEach {
                provider = RxMoyaProvider<GitHub>(endpointClosure: failureEndpointClosure, stubClosure: MoyaProvider.immediatelyStub)
            }
            
            it("returns the correct error message") {
                var receivedError: Moya.Error?
                
                waitUntil { done in
                    _ = provider.request(.zen).subscribe(onError: { error in
                        receivedError = error as? Moya.Error
                        done()
                    })
                }
                
                switch receivedError {
                case .some(.underlying(let error)):
                    expect(error.localizedDescription) == "Houston, we have a problem"
                default:
                    fail("expected an Underlying error that Houston has a problem")
                }
            }
            
            it("returns an error") {
                var errored = false
                
                let target: GitHub = .zen
                _ = provider.request(target).subscribe(onError: { error in
                    errored = true
                })
                
                expect(errored).to(beTruthy())
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
            
            it("returns identical response for inflight requests") {
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
                    expect(receivedResponse).toNot( beNil() )
                    expect(receivedResponse).to( beIdenticalToResponse(response) )
                    expect(provider.inflightRequests.count).to( equal(1) )
                })
                
                // Allow for network request to complete
                expect(provider.inflightRequests.count).toEventually( equal(0) )
            }
        }
    }
}
