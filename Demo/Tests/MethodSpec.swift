import Quick
import Moya
import Nimble

class MethodSpec: QuickSpec {
    override func spec() {
        describe("supportsMultipart") {
            let expectations: [(Moya.Method, Bool)] = [
                (.get, false),
                (.post, true),
                (.put, true),
                (.delete, false),
                (.options, false),
                (.head, false),
                (.patch, true),
                (.trace, false),
                (.connect, true),
            ]
            for (method, expected) in expectations {
                it("\(method) should \(expected ? "" : "not") support multipart") {
                    expect(method.supportsMultipart) == expected
                }
            }
        }
    }
}
