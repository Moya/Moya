import Quick
import Nimble
@testable import Moya

class MultiTargetSpec: QuickSpec {
    override func spec() {
        describe("MultiTarget") {
            struct StructAPI: TargetType {
                let baseURL = URL(string: "http://example.com")!
                let path = "/endpoint"
                let method = Moya.Method.get
                let parameters: [String: Any]? = ["key": "value"]
                let parameterEncoding: Moya.ParameterEncoding = JSONEncoding.default
                let task = Task.request
                let sampleData = "sample data".data(using: .utf8)!
                let validate = true
            }

            var target: MultiTarget!

            beforeEach {
                target = MultiTarget.target(StructAPI())
            }

            it("uses correct baseURL") {
                expect(target.baseURL) == URL(string: "http://example.com")!
            }

            it("uses correct path") {
                expect(target.path) == "/endpoint"
            }

            it("uses correct parameters") {
                expect(target.parameters?["key"] as? String) == "value"
                expect(target.parameters?.count) == 1
            }

            it("uses correct parameter encoding.") {
                expect(target.parameterEncoding is JSONEncoding) == true
            }

            it("uses correct method") {
                expect(target.method) == Method.get
            }

            it("uses correct task") {
                expect(String(describing: target.task)) == "request" // Hack to avoid implementing Equatable for Task
            }

            it("uses correct sample data") {
                let expectedData = "sample data".data(using: .utf8)!
                expect(target.sampleData).to(equal(expectedData))
            }

            it("uses correct validate") {
                expect(target.validate) == true
            }
        }
    }
}
