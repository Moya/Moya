import Quick
import Moya
import Nimble

class MethodSpec: QuickSpec {
    override func spec() {
        describe("supportsMultipart") {
            let expectations: [(Moya.Method, Bool)] = [
                (.GET, false),
                (.POST, true),
                (.PUT, true),
                (.DELETE, false),
                (.OPTIONS, false),
                (.HEAD, false),
                (.PATCH, true),
                (.TRACE, false),
                (.CONNECT, true),
            ]
            for (method, expected) in expectations {
                it("\(method) should \(expected ? "" : "not") support multipart") {
                    expect(method.supportsMultipart) == expected
                }
            }
        }
    }
}
