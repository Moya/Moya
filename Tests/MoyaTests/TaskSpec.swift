import Quick
import Moya
import Nimble
import Foundation
import Alamofire

final class TaskSpec: QuickSpec {

    override func spec() {

        let encodable: [String: String] = ["Hello": "Moya"]

        context("QueryParams related") {

            it("returns the associated values in taskParameters()") {
                let encoder = URLEncodedFormEncoder()
                let queryParams: Task.QueryParams = .query(encodable, encoder)
                let taskparameters = try? queryParams.taskParameters()

                let returnedEncodable = taskparameters?.0 as? [String: String]
                expect(returnedEncodable).to(equal(encodable))
                let parameterEncoder = taskparameters?.1 as? URLEncodedFormParameterEncoder
                expect(parameterEncoder?.encoder).to(be(encoder))
            }
        }

        context("BodyParams related") {
            context("when value is .urlEncoded") {
                it("returns the associated values in taskParameters()") {
                    let encoder = URLEncodedFormEncoder()
                    let queryParams: Task.BodyParams = .urlEncoded(encodable, encoder)
                    let taskparameters = try? queryParams.taskParameters()

                    let returnedEncodable = taskparameters?.0 as? [String: String]
                    expect(returnedEncodable).to(equal(encodable))
                    let parameterEncoder = taskparameters?.1 as? URLEncodedFormParameterEncoder
                    expect(parameterEncoder?.encoder).to(be(encoder))
                }
            }

            context("when value is .custom") {
                it("forbids usage of JSONParameterEncoder") {
                    let queryParams: Task.BodyParams = .custom(encodable, Alamofire.JSONParameterEncoder.default)
                    expect { try queryParams.taskParameters() }.to(throwError())
                }

                it("forbids usage of URLEncodedParameterEncoder") {
                    let queryParams: Task.BodyParams = .custom(encodable, Alamofire.URLEncodedFormParameterEncoder.default)
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
                    let encoder = JSONEncoder()
                    let queryParams: Task.BodyParams = .json(encodable, encoder)
                    let taskparameters = try? queryParams.taskParameters()

                    let returnedEncodable = taskparameters?.0 as? [String: String]
                    expect(returnedEncodable).to(equal(encodable))
                    let parameterEncoder = taskparameters?.1 as? JSONParameterEncoder
                    expect(parameterEncoder?.encoder).to(be(encoder))
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
