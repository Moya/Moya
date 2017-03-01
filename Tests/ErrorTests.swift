import Quick
import Nimble
@testable
import Moya

class ErrorTests: QuickSpec {
    override func spec() {

        var response: Response!

        beforeEach {
            response = Response(statusCode: 200, data: Data(), request: nil, response: nil)
        }

        describe("response computed variable") {

            it("should handle ImageMapping error") {
                let error = MoyaError.imageMapping(response)

                expect(error.response) == response
            }

            it("should handle JSONMapping error") {
                let error = MoyaError.jsonMapping(response)

                expect(error.response) == response
            }

            it("should handle StringMapping error") {
                let error = MoyaError.stringMapping(response)

                expect(error.response) == response
            }

            it("should handle StatusCode error") {
                let error = MoyaError.statusCode(response)

                expect(error.response) == response
            }

            it("should not handle Underlying error ") {
                let nsError = NSError(domain: "Domain", code: 200, userInfo: ["data" : "some data"])
                let error = MoyaError.underlying(nsError)

                expect(error.response).to( beNil() )
            }
        }

        describe("mapping a result with empty data") {
            let response = Response(statusCode: 200, data: Data())

            it("fails on mapJSON with default parameter") {
                var mapJSONFailed = false
                do {
                    let _ = try response.mapJSON()
                } catch {
                    mapJSONFailed = true
                }

                expect(mapJSONFailed).to(beTruthy())
            }

            it("returns default non-nil value on mapJSON with overridden parameter") {
                var succeeded = true
                do {
                    let _ = try response.mapJSON(failsOnEmptyData: false)
                } catch {
                    succeeded = false
                }

                expect(succeeded).to(beTruthy())
            }
        }

        describe("Alamofire responses should return the errors where appropriate") {
            it("should return the underlying error in spite of having a response and data") {
                let underlyingError = NSError(domain: "", code: 0, userInfo: nil)
                let request = NSURLRequest() as URLRequest
                let response = HTTPURLResponse()
                let data = Data()
                let result = convertResponseToResult(response, request: request, data: data, error: underlyingError)
                switch result {
                case let .failure(error):
                    switch error {
                    case let .underlying(e):
                        expect(e as NSError) == underlyingError
                    default:
                        XCTFail("expected to get underlying error")
                    }

                case .success:
                    XCTFail("expected to be failing result")
                }
            }
        }
    }
}
