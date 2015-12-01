import Quick
import Nimble
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
    }
}
