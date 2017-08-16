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

                it("didn't update any of the request properties") {
                    expect(request?.httpBody).to(beNil())
                    expect(request?.url?.absoluteString).to(equal(endpoint.url))
                    expect(request?.allHTTPHeaderFields).to(equal(endpoint.httpHeaderFields))
                    expect(request?.httpMethod).to(equal(endpoint.method.rawValue))
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

                it("updated httpBody") {
                    expect(request?.httpBody).to(equal(data))
                }

                it("didn't update any of the other properties") {
                    expect(request?.url?.absoluteString).to(equal(endpoint.url))
                    expect(request?.allHTTPHeaderFields).to(equal(endpoint.httpHeaderFields))
                    expect(request?.httpMethod).to(equal(endpoint.method.rawValue))
                }
            }

            context("when task is .requestParameters") {
                let parameters = ["Nemesis": "Harvey"]
                let encoding = JSONEncoding.default
                var request: URLRequest?

                beforeEach {
                    endpoint = endpoint.replacing(task: .requestParameters(parameters: parameters, encoding: encoding))
                    request = endpoint.urlRequest
                }

                it("updates the request correcly") {
                    let newEndpoint = endpoint.replacing(task: .requestPlain)
                    let newRequest = newEndpoint.urlRequest
                    let newEncodedRequest = try? encoding.encode(newRequest!, with: parameters)

                    expect(request?.httpBody).to(equal(newEncodedRequest?.httpBody))
                    expect(request?.url?.absoluteString).to(equal(newEncodedRequest?.url?.absoluteString))
                    expect(request?.allHTTPHeaderFields).to(equal(newEncodedRequest?.allHTTPHeaderFields))
                    expect(request?.httpMethod).to(equal(newEncodedRequest?.httpMethod))
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
