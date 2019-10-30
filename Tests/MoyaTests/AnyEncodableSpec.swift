import Quick
import Nimble
import Moya
import Foundation

final class AnyEncodableSpec: QuickSpec {
    override func spec() {
        let encodable: [String: String] = ["Hello": "Moya"]

        it("only encodes the embedded value") {
            let encoder = JSONEncoder()
            let encodedEncodable = try? encoder.encode(encodable)
            let encodedAnyEncodable = try? encoder.encode(AnyEncodable(encodable))

            expect(encodedEncodable).to(equal(encodedAnyEncodable))
        }

        it("returns the embedded encodable of a AnyEncodable stack") {
            let anyEncodable = AnyEncodable(AnyEncodable(AnyEncodable(encodable)))
            let resultEncodable = anyEncodable.underlyingEncodable as? [String: String]
            expect(resultEncodable?.count).to(equal(1))
            expect(resultEncodable?["Hello"]).to(equal("Moya"))
        }
    }
}
