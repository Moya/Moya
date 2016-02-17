import Quick
import Moya
import Nimble

extension Moya.ParameterEncoding: Equatable {
}

public func ==(lhs: Moya.ParameterEncoding, rhs: Moya.ParameterEncoding) -> Bool {
    return String(stringInterpolationSegment: lhs) == String(stringInterpolationSegment: rhs)
}

class EndpointSpec: QuickSpec {
    override func spec() {
        describe("an endpoint") {
            var endpoint: Endpoint<GitHub>!
            
            beforeEach {
                let target: GitHub = .Zen
                let parameters = ["Nemesis": "Harvey"]
                let headerFields = ["Title": "Dominar"]
                endpoint = Endpoint<GitHub>(URL: url(target), sampleResponseClosure: {.NetworkResponse(200, target.sampleData)}, method: Moya.Method.GET, parameters: parameters, parameterEncoding: .JSON, httpHeaderFields: headerFields)
            }
            
            it("returns a new endpoint for endpointByAddingParameters") {
                let message = "I hate it when villains quote Shakespeare."
                let newEndpoint = endpoint.endpointByAddingParameters(["message": message])
                let newEndpointMessageObject: AnyObject? = newEndpoint.parameters?["message"]
                let newEndpointMessage = newEndpointMessageObject as? String
                
                // Make sure our closure updated the sample response, as proof that it can modify the Endpoint
                expect(newEndpointMessage).to(equal(message))
                
                // Compare other properties to ensure they've been copied correctly
                expect(newEndpoint.URL).to(equal(endpoint.URL))
                expect(newEndpoint.method).to(equal(endpoint.method))
                expect(newEndpoint.parameterEncoding).to(equal(endpoint.parameterEncoding))
                expect(newEndpoint.httpHeaderFields?.count).to(equal(endpoint.httpHeaderFields?.count))
            }
            
            it("returns a new endpoint for endpointByAddingHTTPHeaderFields") {
                let agent = "Zalbinian"
                let newEndpoint = endpoint.endpointByAddingHTTPHeaderFields(["User-Agent": agent])
                let newEndpointAgent = newEndpoint.httpHeaderFields?["User-Agent"]
                
                // Make sure our closure updated the sample response, as proof that it can modify the Endpoint
                expect(newEndpointAgent).to(equal(agent))
                
                // Compare other properties to ensure they've been copied correctly
                expect(newEndpoint.URL).to(equal(endpoint.URL))
                expect(newEndpoint.method).to(equal(endpoint.method))
                expect(newEndpoint.parameters?.count).to(equal(endpoint.parameters?.count))
                expect(newEndpoint.parameterEncoding).to(equal(endpoint.parameterEncoding))
            }

            it ("returns a new endpoint for endpointByAddingParameterEncoding") {
                let parameterEncoding = Moya.ParameterEncoding.JSON
                let newEndpoint = endpoint.endpointByAddingParameterEncoding(parameterEncoding)

                // Make sure we updated the parameter encoding
                expect(newEndpoint.parameterEncoding).to(equal(parameterEncoding))

                // Compare other properties to ensure they've been copied correctly
                expect(newEndpoint.URL).to(equal(endpoint.URL))
                expect(newEndpoint.method).to(equal(endpoint.method))
                expect(newEndpoint.parameters?.count).to(equal(endpoint.parameters?.count))
                expect(newEndpoint.httpHeaderFields?.count).to(equal(endpoint.httpHeaderFields?.count))
            }
            
            it ("returns a new endpoint for endpointByAdding with all parameters") {
                let parameterEncoding = Moya.ParameterEncoding.URL
                let agent = "Zalbinian"
                let message = "I hate it when villains quote Shakespeare."
                let newEndpoint = endpoint.endpointByAdding(
                    parameters: ["message": message],
                    httpHeaderFields: ["User-Agent": agent],
                    parameterEncoding: parameterEncoding
                )
                
                let newEndpointAgent = newEndpoint.httpHeaderFields?["User-Agent"]
                let newEndpointMessage = newEndpoint.parameters?["message"] as? String
                
                // Make sure our closure updated the sample response, as proof that it can modify the Endpoint
                expect(newEndpointMessage).to(equal(message))
                expect(newEndpointAgent).to(equal(agent))
                expect(newEndpoint.parameterEncoding).to(equal(parameterEncoding))
            }
            
            it("returns a correct URL request") {
                let request = endpoint.urlRequest
                expect(request.URL!.absoluteString).to(equal("https://api.github.com/zen"))
                expect(NSString(data: request.HTTPBody!, encoding: 4)).to(equal("{\"Nemesis\":\"Harvey\"}"))
                let titleObject: AnyObject? = endpoint.httpHeaderFields?["Title"]
                let title = titleObject as? String
                expect(title).to(equal("Dominar"))
            }
        }
    }
}
