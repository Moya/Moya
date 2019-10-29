import Quick
import Moya
import Nimble
import Foundation

final class TaskSpec: QuickSpec {

    override func spec() {

        let encodable: [String: String] = ["Hello": "Moya"]

        describe("Task.QueryParams enforces usage of correct encoder") {
            it("allows .query destination") {
                let encoder = URLEncodedFormParameterEncoder(destination: .queryString)
                let queryParams: Task.QueryParams = .query(encodable, encoder)
                expect { try queryParams.taskParameters() }.toNot(throwError())
            }

            it("forbids .httpBody destination") {
                let encoder = URLEncodedFormParameterEncoder(destination: .httpBody)
                let queryParams: Task.QueryParams = .query(encodable, encoder)
                expect { try queryParams.taskParameters() }.to(throwError())
            }

            it("forbids .methodDependant destination") {
                let encoder = URLEncodedFormParameterEncoder(destination: .methodDependent)
                let queryParams: Task.QueryParams = .query(encodable, encoder)
                expect { try queryParams.taskParameters() }.to(throwError())
            }
        }

        describe("Task.BodyParams enforces usage of correct encoder") {
            context("when value is .urlEncoded") {

                it("allows .httpBody destination") {
                    let encoder = URLEncodedFormParameterEncoder(destination: .httpBody)
                    let queryParams: Task.BodyParams = .urlEncoded(encodable, encoder)
                    expect { try queryParams.taskParameters() }.toNot(throwError())
                }

                it("forbid .query destination") {
                    let encoder = URLEncodedFormParameterEncoder(destination: .queryString)
                    let queryParams: Task.BodyParams = .urlEncoded(encodable, encoder)
                    expect { try queryParams.taskParameters() }.to(throwError())
                }

                it("forbid .methodDependant destination") {
                    let encoder = URLEncodedFormParameterEncoder(destination: .methodDependent)
                    let queryParams: Task.BodyParams = .urlEncoded(encodable, encoder)
                    expect { try queryParams.taskParameters() }.to(throwError())
                }
            }

            context("when value is .custom") {
                it("forbids usage of JSONParameterEncoder") {
                    let encoder = JSONParameterEncoder.default
                    let queryParams: Task.BodyParams = .custom(encodable, encoder)
                    expect { try queryParams.taskParameters() }.to(throwError())
                }

                it("forbids usage of URLEncodedParameterEncoder") {
                    let encoder = URLEncodedFormParameterEncoder.default
                    let queryParams: Task.BodyParams = .custom(encodable, encoder)
                    expect { try queryParams.taskParameters() }.to(throwError())
                }

                it("allows other encoders") {
                    let encoder = PropertyListEncoder.default
                    let queryParams: Task.BodyParams = .custom(encodable, encoder)
                    expect { try queryParams.taskParameters() }.toNot(throwError())
                }
            }
        }
    }
}
