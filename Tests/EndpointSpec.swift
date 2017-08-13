import Quick
import Moya
import Nimble

class EndpointSpec: QuickSpec {
    override func spec() {
        var endpoint: Endpoint<GitHub>!

        beforeEach {
            let target: GitHub = .zen
            let headerFields = ["Title": "Dominar"]
            endpoint = Endpoint<GitHub>(url: url(target), sampleResponseClosure: {.networkResponse(200, target.sampleData)}, method: Moya.Method.get, task: .requestPlain, httpHeaderFields: headerFields)
        }

        it("returns a new endpoint for adding(newHTTPHeaderFields:)") {
            let agent = "Zalbinian"
            let newEndpoint = endpoint.adding(newHTTPHeaderFields: ["User-Agent": agent])
            let newEndpointAgent = newEndpoint.httpHeaderFields?["User-Agent"]

            // Make sure our closure updated the sample response, as proof that it can modify the Endpoint
            expect(newEndpointAgent).to(equal(agent))

            // Compare other properties to ensure they've been copied correctly
            expect(newEndpoint.url).to(equal(endpoint.url))
            expect(newEndpoint.method).to(equal(endpoint.method))
        }

        it("returns a nil urlRequest for an invalid URL") {
            let badEndpoint = Endpoint<Empty>(url: "some invalid URL", sampleResponseClosure: { .networkResponse(200, Data()) })

            expect(badEndpoint.urlRequest).to(beNil())
        }

        describe("converting to urlRequest") {
            context("when task is .requestPlain") {
                var request: URLRequest?

                beforeEach {
                    endpoint = endpoint.replacing(task: .requestPlain)
                    request = endpoint.urlRequest
                }

                it("returns a correct URL string") {
                    expect(request!.url!.absoluteString).to(equal("https://api.github.com/zen"))
                }

                it("returns a correct title header") {
                    expect(request?.allHTTPHeaderFields?["Title"]).to(equal("Dominar"))
                }
            }

            context("when task is .requestData") {
                var data: Data!
                var request: URLRequest?

                beforeEach {
                    data = "test data".data(using: .utf8)
                    endpoint = endpoint.replacing(task: .requestData(data))
                    request = endpoint.urlRequest
                }

                it("returns a correct httpBody") {
                    expect(request!.httpBody).to(equal(data))
                }

                it("returns a correct URL string") {
                    expect(request!.url!.absoluteString).to(equal("https://api.github.com/zen"))
                }
            }
        }
    }
}

enum Empty {
}

extension Empty: TargetType {
    // None of these matter since the Empty has no cases and can't be instantiated.
    var baseURL: URL { return URL(string: "http://example.com")! }
    var path: String { return "" }
    var method: Moya.Method { return .get }
    var parameters: [String: Any]? { return nil }
    var parameterEncoding: ParameterEncoding { return URLEncoding.default }
    var task: Task { return .requestPlain }
    var sampleData: Data { return Data() }
    var headers: [String: String]? { return nil }
}
