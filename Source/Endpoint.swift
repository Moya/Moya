import Foundation
import Alamofire

/// Used for stubbing responses.
public enum EndpointSampleResponse {

    /// The network returned a response, including status code and data.
    case NetworkResponse(Response)

    /// The network failed to send the request, or failed to retrieve a response (eg a timeout).
    case NetworkError(ErrorType)
}


/// Class for reifying a target of the MoyaTargetType enum unto a concrete Endpoint.
public struct Endpoint<MoyaTargetType> {
    public let URL: String
    public let method: Moya.Method
    public let sampleResponseClosure: () -> EndpointSampleResponse
    public let parameters: [String: AnyObject]?
    public let parameterEncoding: Moya.ParameterEncoding
    public let httpHeaderFields: [String: String]?

    /// Main initializer for Endpoint.
    public init(URL: String,
        @autoclosure(escaping) sampleResponseClosure: () -> EndpointSampleResponse,
        method: Moya.Method = Moya.Method.GET,
        parameters: [String: AnyObject]? = nil,
        parameterEncoding: Moya.ParameterEncoding = .URL,
        httpHeaderFields: [String: String]? = nil) {

        self.URL = URL
        self.sampleResponseClosure = sampleResponseClosure
        self.method = method
        self.parameters = parameters
        self.parameterEncoding = parameterEncoding
        self.httpHeaderFields = httpHeaderFields
    }

    /// Convenience method for creating a new Endpoint with the same properties as the receiver, but with added parameters.
    public func endpointByAddingParameters(parameters: [String: AnyObject]) -> Endpoint<MoyaTargetType> {
        var newParameters = self.parameters ?? [String: AnyObject]()
        for (key, value) in parameters {
            newParameters[key] = value
        }

        return Endpoint(URL: URL, sampleResponseClosure: self.sampleResponseClosure(), method: method, parameters: newParameters, parameterEncoding: parameterEncoding, httpHeaderFields: httpHeaderFields)
    }

    /// Convenience method for creating a new Endpoint with the same properties as the receiver, but with added HTTP header fields.
    public func endpointByAddingHTTPHeaderFields(httpHeaderFields: [String: String]) -> Endpoint<MoyaTargetType> {
        var newHTTPHeaderFields = self.httpHeaderFields ?? [String: String]()
        for (key, value) in httpHeaderFields {
            newHTTPHeaderFields[key] = value
        }
        return Endpoint(URL: URL, sampleResponseClosure: self.sampleResponseClosure(), method: method, parameters: parameters, parameterEncoding: parameterEncoding, httpHeaderFields: newHTTPHeaderFields)
    }
    
    /// Convenience method for creating a new Endpoint with the same properties as the receiver, but with another parameter encoding.
    public func endpointByAddingParameterEncoding(newParameterEncoding: Moya.ParameterEncoding) -> Endpoint<MoyaTargetType> {
        
        return Endpoint(URL: URL, sampleResponseClosure: self.sampleResponseClosure(), method: method, parameters: parameters, parameterEncoding: newParameterEncoding, httpHeaderFields: httpHeaderFields)
    }
}

/// Extension for converting an Endpoint into an NSURLRequest.
extension Endpoint {
    public var urlRequest: NSURLRequest {
        let request: NSMutableURLRequest = NSMutableURLRequest(URL: NSURL(string: URL)!)
        request.HTTPMethod = method.rawValue
        request.allHTTPHeaderFields = httpHeaderFields

        return parameterEncoding.parameterEncoding().encode(request, parameters: parameters).0
    }
}
