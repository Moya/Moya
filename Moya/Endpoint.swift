import Foundation
import Alamofire

/// Used for stubbing responses.
public enum EndpointSampleResponse {
    case Success(Int, () -> NSData)
    case Error(Int?, ErrorType?, (() -> NSData)?)
    case Closure(() -> EndpointSampleResponse)

    func evaluate() -> EndpointSampleResponse {
        switch self {
        case Success, Error: return self
        case Closure(let closure):
            return closure().evaluate()
        }
    }
}


/// Class for reifying a target of the T enum unto a concrete Endpoint
public class Endpoint<T> {
    public let URL: String
    public let method: Moya.Method
    public let sampleResponse: EndpointSampleResponse
    public let parameters: [String: AnyObject]
    public let parameterEncoding: Moya.ParameterEncoding
    public let httpHeaderFields: [String: String]

    /// Main initializer for Endpoint.
    public init(URL: String, sampleResponse: EndpointSampleResponse, method: Moya.Method = Moya.Method.GET, parameters: [String: AnyObject] = [String: AnyObject](), parameterEncoding: Moya.ParameterEncoding = .URL, httpHeaderFields: [String: String] = [String: String]()) {
        self.URL = URL
        self.sampleResponse = sampleResponse
        self.method = method
        self.parameters = parameters
        self.parameterEncoding = parameterEncoding
        self.httpHeaderFields = httpHeaderFields
    }

    /// Convenience method for creating a new Endpoint with the same properties as the receiver, but with added parameters.
    public func endpointByAddingParameters(parameters: [String: AnyObject]) -> Endpoint<T> {
        var newParameters = self.parameters ?? [String: AnyObject]()
        for (key, value) in parameters {
            newParameters[key] = value
        }

        return Endpoint(URL: URL, sampleResponse: sampleResponse, method: method, parameters: newParameters, parameterEncoding: parameterEncoding, httpHeaderFields: httpHeaderFields)
    }

    /// Convenience method for creating a new Endpoint with the same properties as the receiver, but with added HTTP header fields.
    public func endpointByAddingHTTPHeaderFields(httpHeaderFields: [String: String]) -> Endpoint<T> {
        var newHTTPHeaderFields = self.httpHeaderFields ?? [String: String]()
        for (key, value) in httpHeaderFields {
            newHTTPHeaderFields[key] = value
        }

        return Endpoint(URL: URL, sampleResponse: sampleResponse, method: method, parameters: parameters, parameterEncoding: parameterEncoding, httpHeaderFields: newHTTPHeaderFields)
    }
    
    /// Convenience method for creating a new Endpoint with the same properties as the receiver, but with another parameter encoding.
    public func endpointByAddingParameterEncoding(newParameterEncoding: Moya.ParameterEncoding) -> Endpoint<T> {
        
        return Endpoint(URL: URL, sampleResponse: sampleResponse, method: method, parameters: parameters, parameterEncoding: newParameterEncoding, httpHeaderFields: httpHeaderFields)
    }
}

/// Extension for converting an Endpoint into an NSURLRequest.
extension Endpoint {
    public var urlRequest: NSURLRequest {
        let request: NSMutableURLRequest = NSMutableURLRequest(URL: NSURL(string: URL)!)
        request.HTTPMethod = method.method().rawValue
        request.allHTTPHeaderFields = httpHeaderFields

        return parameterEncoding.parameterEncoding().encode(request, parameters: parameters).0
    }
}
