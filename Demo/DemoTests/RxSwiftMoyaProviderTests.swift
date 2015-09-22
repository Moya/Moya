import Quick
import Nimble
import RxMoya
import RxSwift
import Alamofire

class RxSwiftMoyaProviderSpec: QuickSpec {
    override func spec() {
        var provider: RxMoyaProvider<GitHub>!

        beforeEach {
            provider = RxMoyaProvider(stubBehavior: MoyaProvider.ImmediateStubbingBehaviour)
        }

        it("returns a MoyaResponse object") {
            var called = false

            provider.request(.Zen).subscribeNext { (object) -> Void in
                called = true
            }

            expect(called).to(beTruthy())
        }

        it("returns stubbed data for zen request") {
            var message: String?

            let target: GitHub = .Zen
            provider.request(target).subscribeNext { (response) -> Void in
                message = NSString(data: response.data, encoding: NSUTF8StringEncoding) as? String
            }

            let sampleString = NSString(data: (target.sampleData as NSData), encoding: NSUTF8StringEncoding)
            expect(message).to(equal(sampleString))
        }

        it("returns correct data for user profile request") {
            var receivedResponse: NSDictionary?

            let target: GitHub = .UserProfile("ashfurrow")
            provider.request(target).subscribeNext { (response) -> Void in
                receivedResponse = try! NSJSONSerialization.JSONObjectWithData(response.data, options: []) as? NSDictionary
            }

            let sampleData = target.sampleData as NSData
            let sampleResponse: NSDictionary = try! NSJSONSerialization.JSONObjectWithData(sampleData, options: []) as! NSDictionary
            expect(receivedResponse).toNot(beNil())
        }
    }
}

private extension String {
    var URLEscapedString: String {
        return self.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLHostAllowedCharacterSet())!
    }
}

private enum GitHub {
    case Zen
    case UserProfile(String)
}

extension GitHub : MoyaTarget {
    var baseURL: NSURL { return NSURL(string: "https://api.github.com")! }
    var path: String {
        switch self {
        case .Zen:
            return "/zen"
        case .UserProfile(let name):
            return "/users/\(name.URLEscapedString)"
        }
    }
    var method: Moya.Method {
        return .GET
    }
    var parameters: [String: AnyObject] {
        return [:]
    }
    var sampleData: NSData {
        switch self {
        case .Zen:
            return "Half measures are as bad as nothing at all.".dataUsingEncoding(NSUTF8StringEncoding)!
        case .UserProfile(let name):
            return "{\"login\": \"\(name)\", \"id\": 100}".dataUsingEncoding(NSUTF8StringEncoding)!
        }
    }
}

private func url(route: MoyaTarget) -> String {
    return route.baseURL.URLByAppendingPathComponent(route.path).absoluteString
}

private let lazyEndpointClosure = { (target: GitHub) -> Endpoint<GitHub> in
    return Endpoint<GitHub>(URL: url(target), sampleResponse: .Closure({.Success(200, {target.sampleData})}), method: target.method, parameters: target.parameters)
}

private let failureEndpointClosure = { (target: GitHub) -> Endpoint<GitHub> in
    let errorData = "Houston, we have a problem".dataUsingEncoding(NSUTF8StringEncoding)!
    return Endpoint<GitHub>(URL: url(target), sampleResponse: .Error(401, NSError(domain: "com.moya.error", code: 0, userInfo: nil), {errorData}), method: target.method, parameters: target.parameters)
}
