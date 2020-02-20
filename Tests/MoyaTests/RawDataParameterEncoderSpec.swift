import Quick
@testable import Moya
import Nimble
import Foundation

final class RawDataParameterEncoderSpec: QuickSpec {

    override func spec() {

        let requestURL = URL(string: "https://github.com/Moya/Moya")!
        let request = URLRequest(url: requestURL)
        let encoder = RawDataParameterEncoder()

        context("when the encodable is Data") {
            let data = "Some test content".data(using: .utf8)
            let newRequest = try! encoder.encode(data, into: request)

            it("updates the request body") {
                expect(newRequest.httpBody).to(equal(data))
            }

            it("doesn't update anything else") {
                expect(newRequest.url).to(equal(requestURL))
                expect(newRequest.allHTTPHeaderFields).to(equal([:]))
            }
        }

        context("when the encodable is AnyEncodable") {
            let data = "Some test content".data(using: .utf8)
            let encodable = AnyEncodable(data)
            let newRequest = try! encoder.encode(encodable, into: request)

            it("updates the request body") {
                expect(newRequest.httpBody).to(equal(data))
            }

            it("doesn't update anything else") {
                expect(newRequest.url).to(equal(request.url))
                expect(newRequest.allHTTPHeaderFields).to(equal([:]))
            }
        }

        context("when the encodable is something else") {
            let encodable: [String: String] = ["Encodable": "Body"]
            let newRequest = try! encoder.encode(encodable, into: request)

            it("doesn't update the request") {
                expect(newRequest.url).to(equal(requestURL))
                expect(newRequest.httpBody).to(beNil())
                expect(newRequest.allHTTPHeaderFields).to(beNil())
            }
        }
    }
}
