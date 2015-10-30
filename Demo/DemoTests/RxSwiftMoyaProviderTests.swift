import Quick
import Nimble
import Moya
import RxSwift
import Alamofire

class RxSwiftMoyaProviderSpec: QuickSpec {
    override func spec() {
        var provider: RxMoyaProvider<GitHub>!

        beforeEach {
            provider = RxMoyaProvider(stubClosure: MoyaProvider.ImmediatelyStub)
        }

        it("returns a MoyaResponse object") {
            var called = false

            _ = provider.request(.Zen).subscribeNext { (object) -> Void in
                called = true
            }

            expect(called).to(beTruthy())
        }

        it("returns stubbed data for zen request") {
            var message: String?

            let target: GitHub = .Zen
            _ = provider.request(target).subscribeNext { (response) -> Void in
                message = NSString(data: response.data, encoding: NSUTF8StringEncoding) as? String
            }

            let sampleString = NSString(data: (target.sampleData as NSData), encoding: NSUTF8StringEncoding)
            expect(message).to(equal(sampleString))
        }

        it("returns correct data for user profile request") {
            var receivedResponse: NSDictionary?

            let target: GitHub = .UserProfile("ashfurrow")
            _ = provider.request(target).subscribeNext { (response) -> Void in
                receivedResponse = try! NSJSONSerialization.JSONObjectWithData(response.data, options: []) as? NSDictionary
            }

            expect(receivedResponse).toNot(beNil())
        }
    }
}

