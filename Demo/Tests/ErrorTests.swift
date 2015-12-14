import Quick
import Nimble
@testable
import Moya

class ErrorTests: QuickSpec {
    override func spec() {
        
        describe("should convert to NSError") {
        
            var response: Response!
            
            beforeEach {
                response = Response(statusCode: 200, data: NSData(), response: nil)
            }
            
            it("should convert ImageMapping error to NSError") {
                
                let error = Error.ImageMapping(response).nsError
                
                expect(error.domain) == MoyaErrorDomain
                expect(error.code) == MoyaErrorCode.ImageMapping.rawValue
                expect(error.userInfo as? [String : Response]) == ["data" : response]
            }
            
            it("should convert JSONMapping error to NSError") {
                
                let error = Error.JSONMapping(response).nsError
                
                expect(error.domain) == MoyaErrorDomain
                expect(error.code) == MoyaErrorCode.JSONMapping.rawValue
                expect(error.userInfo as? [String : Response]) == ["data" : response]
            }
            
            it("should convert StringMapping error to NSError") {
                
                let error = Error.StringMapping(response).nsError
                
                expect(error.domain) == MoyaErrorDomain
                expect(error.code) == MoyaErrorCode.StringMapping.rawValue
                expect(error.userInfo as? [String : Response]) == ["data" : response]
            }
            
            it("should convert StatusCode error to NSError") {
                
                let error = Error.StatusCode(response).nsError
                
                expect(error.domain) == MoyaErrorDomain
                expect(error.code) == MoyaErrorCode.StatusCode.rawValue
                expect(error.userInfo as? [String : Response]) == ["data" : response]
            }
            
            it("should convert Data error to NSError") {
                
                let error = Error.Data(response).nsError
                
                expect(error.domain) == MoyaErrorDomain
                expect(error.code) == MoyaErrorCode.Data.rawValue
                expect(error.userInfo as? [String : Response]) == ["data" : response]
            }
            
            it("should convert Underlying error to NSError") {
                
                let nsError = NSError(domain: "Domain", code: 200, userInfo: ["data" : "some data"])
                let error = Error.Underlying(nsError).nsError
                
                expect(error.domain) == "Domain"
                expect(error.code) == 200
                expect(error.userInfo as? [String : String]) == ["data" : "some data"]
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
