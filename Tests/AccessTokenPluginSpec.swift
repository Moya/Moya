import Quick
import Nimble
import Moya
import Result

final class AccessTokenPluginSpec: QuickSpec {
    struct TestTarget: TargetType, AccessTokenAuthorizable {
        let baseURL = URL(string: "http://www.api.com/")!
        let path = ""
        let method = Method.get
        let parameters: [String: Any]? = nil
        let parameterEncoding: ParameterEncoding = URLEncoding.default
        let task = Task.request
        let sampleData = Data()

        let shouldAuthorize: Bool
    }

    override func spec() {
        let token = "eyeAm.AJsoN.weBTOKen"
        let plugin = AccessTokenPlugin(token: token)

        it("adds an authorization header to TargetTypes by default") {
            let target = GitHub.zen
            let request = URLRequest(url: target.baseURL)
            let preparedRequest = plugin.prepare(request, target: target)
            expect(preparedRequest.allHTTPHeaderFields) == ["Authorization": "Bearer eyeAm.AJsoN.weBTOKen"]
        }

        it("adds an authorization header to AccessTokenAuthorizables when it's supposed to") {
            let target = TestTarget(shouldAuthorize: true)
            let request = URLRequest(url: target.baseURL)
            let preparedRequest = plugin.prepare(request, target: target)
            expect(preparedRequest.allHTTPHeaderFields) == ["Authorization": "Bearer eyeAm.AJsoN.weBTOKen"]
        }

        it("doesn't add an authorization header to AccessTokenAuthorizables when it's not supposed to") {
            let target = TestTarget(shouldAuthorize: false)
            let request = URLRequest(url: target.baseURL)
            let preparedRequest = plugin.prepare(request, target: target)
            expect(preparedRequest.allHTTPHeaderFields).to(beNil())
        }
    }
}
