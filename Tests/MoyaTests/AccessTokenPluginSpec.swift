import Quick
import Nimble
import Moya
import Foundation

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

    let token = "eyeAm.AJsoN.weBTOKen"
    lazy var plugin = AccessTokenPlugin { self.token }

    override func spec() {
        it("doesn't add an authorization header to TargetTypes by default") {
            let target = GitHub.zen
            let request = URLRequest(url: target.baseURL)
            let preparedRequest = self.plugin.prepare(request, target: target)
            expect(preparedRequest.allHTTPHeaderFields).to(beNil())
        }

        it("doesn't add an authorization header to AccessTokenAuthorizables when AuthorizationType is .none") {
            let authorizationType: AuthorizationType = .none
            let preparedRequest = self.createPreparedRequest(for: authorizationType)

            expect(authorizationType.value).to(beNil())
            expect(preparedRequest.allHTTPHeaderFields).to(beNil())
        }

        it("adds a basic authorization header to AccessTokenAuthorizables when AuthorizationType is .basic") {
            let authorizationType: AuthorizationType = .basic
            let preparedRequest = self.createPreparedRequest(for: authorizationType)

            let authValue = authorizationType.value!
            expect(preparedRequest.allHTTPHeaderFields) == ["Authorization": "\(authValue) \(self.token)"]
        }

        it("adds a bearer authorization header to AccessTokenAuthorizables when AuthorizationType is .bearer") {
            let authorizationType: AuthorizationType = .bearer
            let preparedRequest = self.createPreparedRequest(for: authorizationType)

            let authValue = authorizationType.value!
            expect(preparedRequest.allHTTPHeaderFields) == ["Authorization": "\(authValue) \(self.token)"]
        }

        it("adds a custom authorization header to AccessTokenAuthorizables when AuthorizationType is .custom") {
            let authorizationType: AuthorizationType = .custom("CustomAuthorizationHeader")
            let preparedRequest = self.createPreparedRequest(for: authorizationType)

            let authValue = authorizationType.value!
            expect(preparedRequest.allHTTPHeaderFields) == ["Authorization": "\(authValue) \(self.token)"]
        }
    }

    private func createPreparedRequest(for type: AuthorizationType) -> URLRequest {
        let target = TestTarget(authorizationType: type)
        let request = URLRequest(url: target.baseURL)

        return plugin.prepare(request, target: target)
    }
}
