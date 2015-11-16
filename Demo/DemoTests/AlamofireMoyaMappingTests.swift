import XCTest
import Moya
import Alamofire

final class AlamofireMoyaMappingTests: XCTestCase {
    func testParameterEncodingFaithfullyTranslatesToAFParameterEncoding() {
        var called: Bool = false
        let enc = Moya.ParameterEncoding.Custom { (req, params) -> (NSMutableURLRequest, NSError?) in
            called = true
            return (NSMutableURLRequest(), nil)
        }
        let afCustomEnc = enc.parameterEncoding()
        if case let .Custom(closure) = afCustomEnc {
            let req = NSURLRequest()
            closure(req, nil)
            XCTAssertTrue(called)
        } else {
            XCTFail("Expected custom closure, got \(afCustomEnc)")
        }
    }
}
