import Quick
import Moya
import Nimble
import Foundation
import Alamofire

final class TaskSpec: QuickSpec {

    override func spec() {

        let encodable: [String: String] = ["Hello": "Moya"]

        context("URLParams related") {

            it("returns the associated values in parameters()") {
                let encoder = URLEncodedFormEncoder()
                let urlParams: Task.URLParams = .init(encodable, encoder: encoder)

                let returnedEncodable = urlParams.encodable as? [String: String]
                expect(returnedEncodable).to(equal(encodable))
                let parameterEncoder = urlParams.encoder as? URLEncodedFormParameterEncoder
                expect(parameterEncoder?.encoder).to(be(encoder))
            }
        }

        context("BodyParams related") {
            context("when value is .urlEncoded") {
                it("returns the associated values in parameters()") {
                    let encoder = URLEncodedFormEncoder()
                    let bodyParams: Task.BodyParams = .urlEncoded(encodable, encoder)

                    let returnedEncodable = bodyParams.encodable as? [String: String]
                    expect(returnedEncodable).to(equal(encodable))
                    let parameterEncoder = bodyParams.encoder as? URLEncodedFormParameterEncoder
                    expect(parameterEncoder?.encoder).to(be(encoder))
                }
            }

            context("when value is .json") {
                it("returns the associated values") {
                    let encoder = JSONEncoder()
                    let bodyParams: Task.BodyParams = .json(encodable, encoder)

                    let returnedEncodable = bodyParams.encodable as? [String: String]
                    expect(returnedEncodable).to(equal(encodable))
                    let parameterEncoder = bodyParams.encoder as? JSONParameterEncoder
                    expect(parameterEncoder?.encoder).to(be(encoder))
                }
            }

            context("when value is .raw") {
                let data = "Hello Moya".data(using: .utf8)!
                let bodyParams: Task.BodyParams = .raw(data)

                it("returns the associated values") {
                    let returnedEncodable = bodyParams.encodable as? Data
                    expect(returnedEncodable).to(equal(data))
                }

                it("uses a RawDataParameterEncoder") {
                    let returnedEncoder = bodyParams.encoder as? RawDataParameterEncoder
                    expect(returnedEncoder).to(beAKindOf(RawDataParameterEncoder.self))
                }
            }
        }

        context("CustomParams related") {
            it("forbids usage of JSONParameterEncoder") {
                expect {
                    try Task.CustomParams(encodable, encoder: Alamofire.JSONParameterEncoder.default)
                }.to(throwError())
            }

            it("forbids usage of URLEncodedParameterEncoder") {
                expect {
                    try Task.CustomParams(encodable, encoder: Alamofire.URLEncodedFormParameterEncoder.default)
                }.to(throwError())
            }

            it("returns the associated values for others") {
                let encoder = PropertyListEncoder.default
                let customParams: Task.CustomParams? = try? .init(encodable, encoder: encoder)

                let returnedEncodable = customParams?.encodable as? [String: String]
                expect(returnedEncodable).to(equal(encodable))
                let returnedEncoder = customParams?.encoder as? PropertyListEncoder
                expect(returnedEncoder).to(equal(encoder))
            }
        }
    }
}
