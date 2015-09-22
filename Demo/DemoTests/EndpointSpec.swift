import Quick
import Moya
import Nimble

extension Moya.ParameterEncoding: Equatable {
}

public func ==(lhs: Moya.ParameterEncoding, rhs: Moya.ParameterEncoding) -> Bool {
    switch (lhs, rhs) {
    case (.URL, .URL):
        return true
    case (.JSON, .JSON):
        return true
    case (.PropertyList(_), .PropertyList(_)):
        return true
    case (.Custom(_), .Custom(_)):
        return true
    default:
        return false
    }
}

class EndpointSpec: QuickSpec {
    override func spec() {
        describe("an endpoint") {
            var endpoint: Endpoint<GitHub>!
            
            beforeEach {
                let target: GitHub = .Zen
                let parameters = ["Nemesis": "Harvey"]
                let headerFields = ["Title": "Dominar"]
                endpoint = Endpoint<GitHub>(URL: url(target), sampleResponse: .Success(200, {target.sampleData}), method: Moya.Method.GET, parameters: parameters, parameterEncoding: .JSON, httpHeaderFields: headerFields)
            }
            
            it("returns a new endpoint for endpointByAddingParameters") {
                let message = "I hate it when villains quote Shakespeare."
                let newEndpoint = endpoint.endpointByAddingParameters(["message": message])
                
                let newEndpointMessageObject: AnyObject? = newEndpoint.parameters["message"]
                let newEndpointMessage = newEndpointMessageObject as? String
                // Make sure our closure updated the sample response, as proof that it can modify the Endpoint
                expect(newEndpointMessage).to(equal(message))
                
                // Compare other properties to ensure they've been copied correctly
                expect(newEndpoint.URL).to(equal(endpoint.URL))
                expect(newEndpoint.method).to(equal(endpoint.method))
                expect(newEndpoint.parameterEncoding).to(equal(endpoint.parameterEncoding))
                expect(newEndpoint.httpHeaderFields.count).to(equal(endpoint.httpHeaderFields.count))
            }
            
            it("returns a new endpoint for endpointByAddingHTTPHeaderFields") {
                let agent = "Zalbinian"
                let newEndpoint = endpoint.endpointByAddingHTTPHeaderFields(["User-Agent": agent])
                
                let newEndpointAgentObject: AnyObject? = newEndpoint.httpHeaderFields["User-Agent"]
                let newEndpointAgent = newEndpointAgentObject as? String
                // Make sure our closure updated the sample response, as proof that it can modify the Endpoint
                expect(newEndpointAgent).to(equal(agent))
                
                // Compare other properties to ensure they've been copied correctly
                expect(newEndpoint.URL).to(equal(endpoint.URL))
                expect(newEndpoint.method).to(equal(endpoint.method))
                expect(newEndpoint.parameters.count).to(equal(endpoint.parameters.count))
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
                expect(newEndpoint.parameters.count).to(equal(endpoint.parameters.count))
                expect(newEndpoint.httpHeaderFields.count).to(equal(endpoint.httpHeaderFields.count))
            }
            
            it("returns a correct URL request") {
                let request = endpoint.urlRequest
                expect(request.URL!.absoluteString).to(equal("https://api.github.com/zen"))
                expect(NSString(data: request.HTTPBody!, encoding: 4)).to(equal("{\"Nemesis\":\"Harvey\"}"))
                let titleObject: AnyObject? = endpoint.httpHeaderFields["Title"]
                let title = titleObject as? String
                expect(title).to(equal("Dominar"))
            }
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

private enum HTTPBin: MoyaTarget {
    case BasicAuth

    var baseURL: NSURL { return NSURL(string: "http://httpbin.org")! }
    var path: String {
        switch self {
        case .BasicAuth:
            return "/basic-auth/user/passwd"
        }
    }

    var method: Moya.Method {
        return .GET
    }
    var parameters: [String: AnyObject] {
        switch self {
        default:
            return [:]
        }
    }

    var sampleData: NSData {
        switch self {
        case .BasicAuth:
            return "{\"authenticated\": true, \"user\": \"user\"}".dataUsingEncoding(NSUTF8StringEncoding)!
        }
    }
}

