import Foundation

/// Used for stubbing responses.
public enum EndpointSampleResponse {

    /// The network returned a response, including status code and data.
    case NetworkResponse(Int, NSData)

    /// The network failed to send the request, or failed to retrieve a response (eg a timeout).
    case NetworkError(ErrorType)
}


/// Class for reifying a target of the Target enum unto a concrete Endpoint.
public class Endpoint<Target> {
    public typealias SampleResponseClosure = () -> EndpointSampleResponse

    public let URL: String
    public let method: Moya.Method
    public let sampleResponseClosure: SampleResponseClosure
    public let parameters: [String: AnyObject]?
    public let parameterEncoding: Moya.ParameterEncoding
    public let httpHeaderFields: [String: String]?

    /// Main initializer for Endpoint.
    public init(URL: String,
        sampleResponseClosure: SampleResponseClosure,
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
    public func endpointByAddingParameters(parameters: [String: AnyObject]) -> Endpoint<Target> {
        return endpointByAdding(parameters: parameters)
    }

    /// Convenience method for creating a new Endpoint with the same properties as the receiver, but with added HTTP header fields.
    public func endpointByAddingHTTPHeaderFields(httpHeaderFields: [String: String]) -> Endpoint<Target> {
        return endpointByAdding(httpHeaderFields: httpHeaderFields)
    }
    
    /// Convenience method for creating a new Endpoint with the same properties as the receiver, but with another parameter encoding.
    public func endpointByAddingParameterEncoding(newParameterEncoding: Moya.ParameterEncoding) -> Endpoint<Target> {
        return endpointByAdding(parameterEncoding: newParameterEncoding)
    }
    
    /// Convenience method for creating a new Endpoint, with changes only to the properties we specify as parameters
    public func endpointByAdding(parameters parameters: [String: AnyObject]? = nil, httpHeaderFields: [String: String]? = nil, parameterEncoding: Moya.ParameterEncoding? = nil)  -> Endpoint<Target> {
        let newParameters = addParameters(parameters)
        let newHTTPHeaderFields = addHTTPHeaderFields(httpHeaderFields)
        let newParameterEncoding = parameterEncoding ?? self.parameterEncoding
        return Endpoint(URL: URL, sampleResponseClosure: sampleResponseClosure, method: method, parameters: newParameters, parameterEncoding: newParameterEncoding, httpHeaderFields: newHTTPHeaderFields)
    }
    
    private func addParameters(parameters: [String: AnyObject]?) -> [String: AnyObject]? {
        guard let unwrappedParameters = parameters where unwrappedParameters.count > 0 else {
            return self.parameters
        }
        
        var newParameters = self.parameters ?? [String: AnyObject]()
        unwrappedParameters.forEach { (key, value) in
            newParameters[key] = value
        }
        return newParameters
    }
    
    private func addHTTPHeaderFields(headers: [String: String]?) -> [String: String]? {
        guard let unwrappedHeaders = headers where unwrappedHeaders.count > 0 else {
            return self.httpHeaderFields
        }
        
        var newHTTPHeaderFields = self.httpHeaderFields ?? [String: String]()
        unwrappedHeaders.forEach { (key, value) in
            newHTTPHeaderFields[key] = value
        }
        return newHTTPHeaderFields
    }
}

/// Extension for converting an Endpoint into an NSURLRequest.
extension Endpoint {
    public var urlRequest: NSURLRequest {
        let request: NSMutableURLRequest = NSMutableURLRequest(URL: NSURL(string: URL)!)
        request.HTTPMethod = method.rawValue
        request.allHTTPHeaderFields = httpHeaderFields

        return parameterEncoding.encode(request, parameters: parameters).0
    }
}

/// Required for making Endpoint conform to Equatable.
public func ==<T>(lhs: Endpoint<T>, rhs: Endpoint<T>) -> Bool {
    return lhs.urlRequest.isEqual(rhs.urlRequest)
}

/// Required for using Endpoint as a key type in a Dictionary.
extension Endpoint: Equatable, Hashable {
    public var hashValue: Int {
        return urlRequest.hash
    }
}
