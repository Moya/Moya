import Quick
import Moya
import Nimble
import Foundation

final class TaskSpec: QuickSpec {

    override func spec() {

        let encodable: [String: String] = ["Hello": "Moya"]

        context("QueryParams related") {
            describe("Enforces usage of correct encoder") {
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

            it("returns the associated values in taskParameters()") {
                let encoder = URLEncodedFormParameterEncoder(destination: .queryString)
                let queryParams: Task.QueryParams = .query(encodable, encoder)
                let taskparameters = try? queryParams.taskParameters()

                let returnedEncodable = taskparameters?.0 as? [String: String]
                expect(returnedEncodable).to(equal(encodable))
                let returnedEncoder = taskparameters?.1 as? URLEncodedFormParameterEncoder
                //URLEncodedFormParameterEncoder isn't equatable
                expect(returnedEncoder).toNot(beNil())
                expect(returnedEncoder?.destination).to(equal(encoder.destination))
            }
        }

        context("BodyParams related") {
            context("when value is .urlEncoded") {
                it("allows encoder's .httpBody destination") {
                    let encoder = URLEncodedFormParameterEncoder(destination: .httpBody)
                    let queryParams: Task.BodyParams = .urlEncoded(encodable, encoder)
                    expect { try queryParams.taskParameters() }.toNot(throwError())
                }

                it("forbid encoder's .query destination") {
                    let encoder = URLEncodedFormParameterEncoder(destination: .queryString)
                    let queryParams: Task.BodyParams = .urlEncoded(encodable, encoder)
                    expect { try queryParams.taskParameters() }.to(throwError())
                }

                it("forbid encoder's .methodDependant destination") {
                    let encoder = URLEncodedFormParameterEncoder(destination: .methodDependent)
                    let queryParams: Task.BodyParams = .urlEncoded(encodable, encoder)
                    expect { try queryParams.taskParameters() }.to(throwError())
                }

                it("returns the associated values in taskParameters()") {
                    let encoder = URLEncodedFormParameterEncoder(destination: .httpBody)
                    let queryParams: Task.BodyParams = .urlEncoded(encodable, encoder)
                    let taskparameters = try? queryParams.taskParameters()

                    let returnedEncodable = taskparameters?.0 as? [String: String]
                    expect(returnedEncodable).to(equal(encodable))
                    let returnedEncoder = taskparameters?.1 as? URLEncodedFormParameterEncoder
                    //URLEncodedFormParameterEncoder isn't equatable
                    expect(returnedEncoder).toNot(beNil())
                    expect(returnedEncoder?.destination).to(equal(encoder.destination))
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

                it("returns the associated values for others") {
                    let encoder = PropertyListEncoder.default
                    let queryParams: Task.BodyParams = .custom(encodable, encoder)
                    let taskparameters = try? queryParams.taskParameters()

                    let returnedEncodable = taskparameters?.0 as? [String: String]
                    expect(returnedEncodable).to(equal(encodable))
                    let returnedEncoder = taskparameters?.1 as? PropertyListEncoder
                    expect(returnedEncoder).to(equal(encoder))
                }
            }

            context("when value is .json") {
                it("returns the associated values") {
                    let encoder = JSONParameterEncoder.default
                    let queryParams: Task.BodyParams = .json(encodable, encoder)
                    let taskparameters = try? queryParams.taskParameters()

                    let returnedEncodable = taskparameters?.0 as? [String: String]
                    expect(returnedEncodable).to(equal(encodable))
                    let returnedEncoder = taskparameters?.1 as? JSONParameterEncoder
                    expect(returnedEncoder).to(be(encoder))
                }
            }

            context("when value is .raw") {
                let data = "Hello Moya".data(using: .utf8)!
                let queryParams: Task.BodyParams = .raw(data)
                let taskparameters = try? queryParams.taskParameters()

                it("returns the associated values") {
                    let returnedEncodable = taskparameters?.0 as? Data
                    expect(returnedEncodable).to(equal(data))
                }

                it("uses a RawDataParameterEncoder") {
                    let returnedEncoder = taskparameters?.1 as? RawDataParameterEncoder
                    expect(returnedEncoder).to(beAKindOf(RawDataParameterEncoder.self))
                }
            }
        }
    }
}
