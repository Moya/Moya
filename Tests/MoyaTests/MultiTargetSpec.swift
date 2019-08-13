import Quick
import Nimble
import Foundation

@testable import Moya

final class MultiTargetSpec: QuickSpec {
    override func spec() {
        describe("MultiTarget") {
            struct StructAPI: TargetType {
                let baseURL = URL(string: "http://example.com")!
                let path = "/endpoint"
                let method = Moya.Method.get
                let task = Task.requestParameters(parameters: ["key": "value"], encoding: JSONEncoding.default)
                let sampleData = "sample data".data(using: .utf8)!
                let validationType: ValidationType = .successCodes
                let headers: [String: String]? = ["headerKey": "headerValue"]
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
                if case let .requestParameters(parameters: parameters, encoding: _) = target.task {
                    expect(parameters["key"] as? String) == "value"
                    expect(parameters.count) == 1
                } else {
                    fail("expected task type `.requestParameters`, was \(String(describing: target.task))")
                }
            }

            it("uses correct parameter encoding.") {
                if case let .requestParameters(parameters: _, encoding: parameterEncoding) = target.task {
                    expect(parameterEncoding is JSONEncoding) == true
                } else {
                    fail("expected task type `.requestParameters`, was \(String(describing: target.task))")
                }
            }

            it("uses correct method") {
                expect(target.method) == Method.get
            }

            it("uses correct task") {
                expect(String(describing: target.task)).to(beginWith("requestParameters")) // Hack to avoid implementing Equatable for Task
            }

            it("uses correct sample data") {
                let expectedData = "sample data".data(using: .utf8)!
                expect(target.sampleData).to(equal(expectedData))
            }

            it("uses correct validation type") {
                expect(target.validationType).to(equal(ValidationType.successCodes))
            }

            it("uses correct headers") {
                expect(target.headers) == ["headerKey": "headerValue"]
            }
        }
    }
}
