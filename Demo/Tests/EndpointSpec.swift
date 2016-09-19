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
                endpoint = Endpoint<GitHub>(URL: url(target), sampleResponseClosure: {.networkResponse(200, target.sampleData)}, method: Moya.Method.GET, parameters: parameters, parameterEncoding: JSONEncoding(), httpHeaderFields: headerFields)
            }
            
            it("returns a new endpoint for endpointByAddingParameters") {
                let message = "I hate it when villains quote Shakespeare."
                let newEndpoint = endpoint.endpointByAddingParameters(["message": message])
                let newEndpointMessageObject: Any? = newEndpoint.parameters?["message"]
                let newEndpointMessage = newEndpointMessageObject as? String
                let encodedRequest = try? endpoint.parameterEncoding.encode(newEndpoint.urlRequest, with: newEndpoint.parameters)
                let newEncodedRequest = try? newEndpoint.parameterEncoding.encode(newEndpoint.urlRequest, with: newEndpoint.parameters)
                
                
                // Make sure our closure updated the sample response, as proof that it can modify the Endpoint
                expect(newEndpointMessage).to(equal(message))
                
                // Compare other properties to ensure they've been copied correctly
                expect(newEndpoint.URL).to(equal(endpoint.URL))
                expect(newEndpoint.method).to(equal(endpoint.method))
                expect(newEndpoint.httpHeaderFields?.count).to(equal(endpoint.httpHeaderFields?.count))
                expect(newEncodedRequest).to(equal(encodedRequest))
            }
            
            it("returns a new endpoint for endpointByAddingHTTPHeaderFields") {
                let agent = "Zalbinian"
                let newEndpoint = endpoint.endpointByAddingHTTPHeaderFields(["User-Agent": agent])
                let newEndpointAgent = newEndpoint.httpHeaderFields?["User-Agent"]
                let encodedRequest = try? endpoint.parameterEncoding.encode(newEndpoint.urlRequest, with: newEndpoint.parameters)
                let newEncodedRequest = try? newEndpoint.parameterEncoding.encode(newEndpoint.urlRequest, with: newEndpoint.parameters)
                
                // Make sure our closure updated the sample response, as proof that it can modify the Endpoint
                expect(newEndpointAgent).to(equal(agent))
                
                // Compare other properties to ensure they've been copied correctly
                expect(newEndpoint.URL).to(equal(endpoint.URL))
                expect(newEndpoint.method).to(equal(endpoint.method))
                expect(newEndpoint.parameters?.count).to(equal(endpoint.parameters?.count))
                expect(newEncodedRequest).to(equal(encodedRequest))
            }

            it ("returns a new endpoint for endpointByAddingParameterEncoding") {
                let parameterEncoding = JSONEncoding()
                let newEndpoint = endpoint.endpointByAddingParameterEncoding(parameterEncoding)
                let encodedRequest = try? parameterEncoding.encode(newEndpoint.urlRequest, with: newEndpoint.parameters)
                let newEncodedRequest = try? newEndpoint.parameterEncoding.encode(newEndpoint.urlRequest, with: newEndpoint.parameters)

                // Make sure we updated the parameter encoding
                expect(newEncodedRequest).to(equal(encodedRequest))

                // Compare other properties to ensure they've been copied correctly
                expect(newEndpoint.URL).to(equal(endpoint.URL))
                expect(newEndpoint.method).to(equal(endpoint.method))
                expect(newEndpoint.parameters?.count).to(equal(endpoint.parameters?.count))
                expect(newEndpoint.httpHeaderFields?.count).to(equal(endpoint.httpHeaderFields?.count))
            }
            
            it ("returns a new endpoint for endpointByAdding with all parameters") {
                let parameterEncoding = URLEncoding()
                let agent = "Zalbinian"
                let message = "I hate it when villains quote Shakespeare."
                let newEndpoint = endpoint.endpointByAdding(
                    parameters: ["message": message],
                    httpHeaderFields: ["User-Agent": agent],
                    parameterEncoding: parameterEncoding
                )
                let encodedRequest = try? parameterEncoding.encode(newEndpoint.urlRequest, with: newEndpoint.parameters)
                let newEncodedRequest = try? newEndpoint.parameterEncoding.encode(newEndpoint.urlRequest, with: newEndpoint.parameters)
                
                
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
        }
    }
}
