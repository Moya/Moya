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
                let task = Task.request(bodyParams: .json(["key": "value"]))
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
                let task = target.task
                guard case Task.request = task else {
                    fail("expected task type `.request`, was \(String(describing: target.task))")
                    return
                }
                let encodable = task.allParameters.first?.0
                expect(encodable).toNot(beNil())
                let dict = encodable! as? [String: String]
                expect(dict).toNot(beNil())
                expect(dict!["key"]) == "value"
                expect(dict!.count) == 1
            }

            it("uses correct parameter encoding.") {
                let task = target.task
                guard case Task.request = task else {
                    fail("expected task type `.request`, was \(String(describing: target.task))")
                    return
                }

                expect(task.allParameters.first?.1).to(beAKindOf(JSONParameterEncoder.self))
            }

            it("uses correct method") {
                expect(target.method) == Method.get
            }

            it("uses correct task") {
                guard case Task.request = target.task else {
                    fail("expected task type `.request`, was \(String(describing: target.task))")
                    return
                }
                expect(true) == true
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
