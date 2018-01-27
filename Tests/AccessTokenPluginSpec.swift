import Quick
import Nimble
import Moya
import Result

final class AccessTokenPluginSpec: QuickSpec {
    struct TestTarget: TargetType, AccessTokenAuthorizable {
        let baseURL = URL(string: "http://www.api.com/")!
        let path = ""
        let method = Method.get
        let task = Task.requestPlain
        let sampleData = Data()
        let headers: [String: String]? = nil
        let authorizationType: AuthorizationType
    }

    override func spec() {
        let token = "eyeAm.AJsoN.weBTOKen"
        let plugin = AccessTokenPlugin(tokenClosure: token)

        it("doesn't add an authorization header to TargetTypes by default") {
            let target = GitHub.zen
            let request = URLRequest(url: target.baseURL)
            let preparedRequest = plugin.prepare(request, target: target)
            expect(preparedRequest.allHTTPHeaderFields).to(beNil())
        }

        it("doesn't add an authorization header to AccessTokenAuthorizables when AuthorizationType is .none") {
            let target = TestTarget(authorizationType: .none)
            let request = URLRequest(url: target.baseURL)
            let preparedRequest = plugin.prepare(request, target: target)
            expect(preparedRequest.allHTTPHeaderFields).to(beNil())
        }

        it("adds a bearer authorization header to AccessTokenAuthorizables when AuthorizationType is .bearer") {
            let target = TestTarget(authorizationType: .bearer)
            let request = URLRequest(url: target.baseURL)
            let preparedRequest = plugin.prepare(request, target: target)
            expect(preparedRequest.allHTTPHeaderFields) == ["Authorization": "Bearer eyeAm.AJsoN.weBTOKen"]
        }

        it("adds a basic authorization header to AccessTokenAuthorizables when AuthorizationType is .basic") {
            let target = TestTarget(authorizationType: .basic)
            let request = URLRequest(url: target.baseURL)
            let preparedRequest = plugin.prepare(request, target: target)
            expect(preparedRequest.allHTTPHeaderFields) == ["Authorization": "Basic eyeAm.AJsoN.weBTOKen"]
        }

    }
}
