import Quick
import Nimble
@testable
import Moya

class ErrorTests: QuickSpec {
    override func spec() {

        var response: Response!

        beforeEach {
            response = Response(statusCode: 200, data: NSData(), response: nil)
        }

        describe("response computed variable") {

            it("should handle ImageMapping error") {
                let error = Error.ImageMapping(response)

                expect(error.response) == response
            }

            it("should handle JSONMapping error") {
                let error = Error.JSONMapping(response)

                expect(error.response) == response
            }

            it("should handle StringMapping error") {
                let error = Error.StringMapping(response)

                expect(error.response) == response
            }

            it("should handle StatusCode error") {
                let error = Error.StatusCode(response)

                expect(error.response) == response
            }

            it("should handle Data error") {
                let error = Error.Data(response)

                expect(error.response) == response
            }

            it("should not handle Underlying error ") {
                let nsError = NSError(domain: "Domain", code: 200, userInfo: ["data" : "some data"])
                let error = Error.Underlying(nsError)

                expect(error.response).to( beNil() )
            }
        }

        describe("Alamofire responses should return the errors where appropriate") {
            it("should return the underlying error in spite of having a response and data") {
                let underlyingError = NSError(domain: "", code: 0, userInfo: nil)
                let response = NSHTTPURLResponse()
                let data = NSData()
                let result = convertResponseToResult(response, data: data, error: underlyingError)
                switch result {
                case let .Failure(error):
                    switch error {
                    case let .Underlying(e):
                        expect(e as NSError) == underlyingError
                    default:
                        XCTFail("expected to get underlying error")
                    }

                case .Success:
                    XCTFail("expected to be failing result")
                }
            }
        }
    }
}
