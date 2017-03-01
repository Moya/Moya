import Quick
import Moya
import Nimble

class EndpointSpec: QuickSpec {
    override func spec() {
        describe("an endpoint") {
            var endpoint: Endpoint<GitHub>!
            
            beforeEach {
                let target: GitHub = .zen
                let parameters = ["Nemesis": "Harvey"]
                let headerFields = ["Title": "Dominar"]
                endpoint = Endpoint<GitHub>(url: url(target), sampleResponseClosure: {.networkResponse(200, target.sampleData)}, method: Moya.Method.get, parameters: parameters, parameterEncoding: JSONEncoding.default, httpHeaderFields: headerFields)
            }
            
            it("returns a new endpoint for adding(newParameters:)") {
                let message = "I hate it when villains quote Shakespeare."
                let newEndpoint = endpoint.adding(newParameters: ["message": message])
                let newEndpointMessageObject: Any? = newEndpoint.parameters?["message"]
                let newEndpointMessage = newEndpointMessageObject as? String
                let encodedRequest = try? endpoint.parameterEncoding.encode(newEndpoint.urlRequest!, with: newEndpoint.parameters)
                let newEncodedRequest = try? newEndpoint.parameterEncoding.encode(newEndpoint.urlRequest!, with: newEndpoint.parameters)
                
                
                // Make sure our closure updated the sample response, as proof that it can modify the Endpoint
                expect(newEndpointMessage).to(equal(message))
                
                // Compare other properties to ensure they've been copied correctly
                expect(newEndpoint.url).to(equal(endpoint.url))
                expect(newEndpoint.method).to(equal(endpoint.method))
                expect(newEndpoint.httpHeaderFields?.count).to(equal(endpoint.httpHeaderFields?.count))
                expect(newEncodedRequest).to(equal(encodedRequest))
            }
            
            it("returns a new endpoint for adding(newHTTPHeaderFields:)") {
                let agent = "Zalbinian"
                let newEndpoint = endpoint.adding(newHTTPHeaderFields: ["User-Agent": agent])
                let newEndpointAgent = newEndpoint.httpHeaderFields?["User-Agent"]
                let encodedRequest = try? endpoint.parameterEncoding.encode(newEndpoint.urlRequest!, with: newEndpoint.parameters)
                let newEncodedRequest = try? newEndpoint.parameterEncoding.encode(newEndpoint.urlRequest!, with: newEndpoint.parameters)
                
                // Make sure our closure updated the sample response, as proof that it can modify the Endpoint
                expect(newEndpointAgent).to(equal(agent))
                
                // Compare other properties to ensure they've been copied correctly
                expect(newEndpoint.url).to(equal(endpoint.url))
                expect(newEndpoint.method).to(equal(endpoint.method))
                expect(newEndpoint.parameters?.count).to(equal(endpoint.parameters?.count))
                expect(newEncodedRequest).to(equal(encodedRequest))
            }

            it ("returns a new endpoint for adding(newParameterEncoding:)") {
                let parameterEncoding = JSONEncoding.default
                let newEndpoint = endpoint.adding(newParameterEncoding: parameterEncoding)
                let encodedRequest = try? parameterEncoding.encode(newEndpoint.urlRequest!, with: newEndpoint.parameters)
                let newEncodedRequest = try? newEndpoint.parameterEncoding.encode(newEndpoint.urlRequest!, with: newEndpoint.parameters)

                // Make sure we updated the parameter encoding
                expect(newEncodedRequest).to(equal(encodedRequest))

                // Compare other properties to ensure they've been copied correctly
                expect(newEndpoint.url).to(equal(endpoint.url))
                expect(newEndpoint.method).to(equal(endpoint.method))
                expect(newEndpoint.parameters?.count).to(equal(endpoint.parameters?.count))
                expect(newEndpoint.httpHeaderFields?.count).to(equal(endpoint.httpHeaderFields?.count))
            }
            
            it ("returns a new endpoint for endpointByAdding with all parameters") {
                let parameterEncoding = URLEncoding.default
                let agent = "Zalbinian"
                let message = "I hate it when villains quote Shakespeare."
                let newEndpoint = endpoint.adding(
                    parameters: ["message": message],
                    httpHeaderFields: ["User-Agent": agent],
                    parameterEncoding: parameterEncoding
                )
                let encodedRequest = try? parameterEncoding.encode(newEndpoint.urlRequest!, with: newEndpoint.parameters)
                let newEncodedRequest = try? newEndpoint.parameterEncoding.encode(newEndpoint.urlRequest!, with: newEndpoint.parameters)
                
                
                let newEndpointAgent = newEndpoint.httpHeaderFields?["User-Agent"]
                let newEndpointMessage = newEndpoint.parameters?["message"] as? String
                
                // Make sure our closure updated the sample response, as proof that it can modify the Endpoint
                expect(newEndpointMessage).to(equal(message))
                expect(newEndpointAgent).to(equal(agent))
                expect(newEncodedRequest).to(equal(encodedRequest))
            }
            
            it("returns a correct URL request") {
                let request = endpoint.urlRequest
                expect(request!.url!.absoluteString).to(equal("https://api.github.com/zen"))
                expect(String(data: request!.httpBody!, encoding: .utf8)).to(equal("{\"Nemesis\":\"Harvey\"}"))
                let titleObject: Any? = endpoint.httpHeaderFields?["Title"]
                let title = titleObject as? String
                expect(title).to(equal("Dominar"))
            }

            it("returns a nil urlRequest for an invalid URL") {
                let badEndpoint = Endpoint<Empty>(url: "some invalid URL", sampleResponseClosure: { .networkResponse(200, Data()) })

                expect(badEndpoint.urlRequest).to( beNil() )
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
    var task: Task { return .request }
    var sampleData: Data { return Data() }
}
