import Quick
import Nimble
import Moya
import Result

final class AccessTokenPluginSpec: QuickSpec {
    struct TestTarget: TargetType, AccessControllable {
        let baseURL: URL
        let path: String
        let method: Moya.Method
        let task: Task
        let sampleData: Data
        let headers: [String: String]?
        let accessControlType: AccessControlType

        init(baseURL: URL = URL(string: "http://www.api.com/")!,
             path: String = "",
             method: Moya.Method = .get,
             task: Task = .requestPlain,
             sampleData: Data = Data(),
             headers: [String: String]? = nil,
             accessControlType: AccessControlType) {
            self.baseURL = baseURL
            self.path = path
            self.method = method
            self.task = task
            self.sampleData = sampleData
            self.headers = headers
            self.accessControlType = accessControlType
        }
    }

    override func spec() {
        let tokenClosure = { return "eyeAm.AJsoN.weBTOKen" }
        let plugin = AccessTokenPlugin(tokenClosure: tokenClosure)

        it("doesn't add an authorization header to TargetTypes by default") {
            let target = GitHub.zen
            let request = URLRequest(url: target.baseURL)
            let preparedRequest = plugin.prepare(request, target: target)
            expect(preparedRequest.allHTTPHeaderFields).to(beNil())
        }

        it("doesn't add query parameter authentication to TargetTypes by default") {
            let target = GitHub.zen
            let request = URLRequest(url: target.baseURL)
            let preparedRequest = plugin.prepare(request, target: target)
            let components = URLComponents(url: preparedRequest.url!, resolvingAgainstBaseURL: false)!
            expect(components.queryItems).to(beNil())
        }

        it("doesn't add an authorization header to AccessControllables when AccessControlType is .none") {
            let target = TestTarget(accessControlType: .none)
            let request = URLRequest(url: target.baseURL)
            let preparedRequest = plugin.prepare(request, target: target)
            expect(preparedRequest.allHTTPHeaderFields).to(beNil())
        }

        it("doesn't add query parameter authentication to AccessControllables when AccessControlType is .none") {
            let target = TestTarget(accessControlType: .none)
            let request = URLRequest(url: target.baseURL)
            let preparedRequest = plugin.prepare(request, target: target)
            let components = URLComponents(url: preparedRequest.url!, resolvingAgainstBaseURL: false)!
            expect(components.queryItems).to(beNil())
        }

        it("adds a bearer authorization header to AccessControllables when AccessControlType is .http and the scheme is .bearer") {
            let target = TestTarget(accessControlType: .http(scheme: .bearer))
            let request = URLRequest(url: target.baseURL)
            let preparedRequest = plugin.prepare(request, target: target)
            expect(preparedRequest.allHTTPHeaderFields) == ["Authorization": "Bearer eyeAm.AJsoN.weBTOKen"]
        }

        it("adds a basic authorization header to AccessControllables when AccessControlType is .http and the scheme is .basic") {
            let target = TestTarget(accessControlType: .http(scheme: .basic))
            let request = URLRequest(url: target.baseURL)
            let preparedRequest = plugin.prepare(request, target: target)
            expect(preparedRequest.allHTTPHeaderFields) == ["Authorization": "Basic eyeAm.AJsoN.weBTOKen"]
        }

        it("adds a custom authorization header to AccessControllables when AccessControlType is .apiKey and the placement is .header") {
            let target = TestTarget(accessControlType: .apiKey(name: "X-Access-Token", placement: .header))
            let request = URLRequest(url: target.baseURL)
            let preparedRequest = plugin.prepare(request, target: target)
            expect(preparedRequest.allHTTPHeaderFields) == ["X-Access-Token": "eyeAm.AJsoN.weBTOKen"]
        }

        it("adds a query parameter to AccessControllables when AccessControlType is .apiKey and the placement is .queryParameter") {
            let target = TestTarget(accessControlType: .apiKey(name: "accessToken", placement: .queryParameter))
            let request = URLRequest(url: target.baseURL)
            let preparedRequest = plugin.prepare(request, target: target)
            let components = URLComponents(url: preparedRequest.url!, resolvingAgainstBaseURL: false)!
            expect(components.queryItems) == [URLQueryItem(name: "accessToken", value: "eyeAm.AJsoN.weBTOKen")]
        }

        it("appends a query parameter to AccessControllables when AccessControlType is .apiKey and the placement is .queryParameter") {
            let target = TestTarget(baseURL: URL(string: "http://www.api.com/?key=value")!,
                                    accessControlType: .apiKey(name: "accessToken", placement: .queryParameter))
            let request = URLRequest(url: target.baseURL)
            let preparedRequest = plugin.prepare(request, target: target)
            let components = URLComponents(url: preparedRequest.url!, resolvingAgainstBaseURL: false)!
            expect(components.queryItems) == [
                URLQueryItem(name: "key", value: "value"),
                URLQueryItem(name: "accessToken", value: "eyeAm.AJsoN.weBTOKen")
            ]
        }
    }
}
