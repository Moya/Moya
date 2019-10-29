import Quick
import Moya
import Nimble
import Foundation

final class RawDataParameterEncoderSpec: QuickSpec {

    override func spec() {

        var request: URLRequest!
        var encoder: RawDataParameterEncoder!

        beforeEach {
            request = URLRequest(url: URL(string:"https://github.com/Moya/Moya")!)
            encoder = RawDataParameterEncoder()
        }

        context("when the encodable is Data") {

            let data = "Some test content".data(using: .utf8)

            it("updates the request body") {
                let newRequest = try! encoder.encode(data, into: request)
                expect(newRequest.httpBody).to(equal(data))
            }

            it("doesn't update anything else") {
                var newRequest = try! encoder.encode(data, into: request)
                newRequest.httpBody = nil
                expect(newRequest).to(equal(request))
            }
        }

        context("when the encodable is AnyEncodable") {
            let data = "Some test content".data(using: .utf8)
            let encodable = AnyEncodable(data)

            it("updates the request body") {
                request = try! encoder.encode(encodable, into: request)
                expect(request.httpBody).to(equal(data))
            }

            it("doesn't update anything else") {
                var newRequest = try! encoder.encode(data, into: request)
                newRequest.httpBody = nil
                expect(newRequest).to(equal(request))
            }
        }

        context("when the encodable is somthing else") {
            let encodable: [String: String] = ["Encodable": "Body"]

            it("doesn't update the request") {
                var newRequest = try! encoder.encode(encodable, into: request)
                newRequest.httpBody = nil
                expect(newRequest).to(equal(request))
            }
        }
    }
}
