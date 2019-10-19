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
                let task = Task.request(jsonParams: ["key": "value"])
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
                if case let .request(_, parameters) = target.task {
                    let encodable = parameters?.first?.1
                    expect(encodable).toNot(beNil())
                    let dict = encodable! as? [String: String]
                    expect(dict).toNot(beNil())
                    expect(dict!["key"]) == "value"
                    expect(dict!.count) == 1
                } else {
                    fail("expected task type `.requestParameters`, was \(String(describing: target.task))")
                }
            }

            it("uses correct parameter encoding.") {
                if case let .request(_, taskParameters) = target.task {
                    expect(taskParameters?.first?.0 is JSONParameterEncoder) == true
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
