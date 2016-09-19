import Foundation
import Alamofire

/// Used for stubbing responses.
public enum EndpointSampleResponse {

    /// The network returned a response, including status code and data.
    case networkResponse(Int, Data)

    /// The network failed to send the request, or failed to retrieve a response (eg a timeout).
    case networkError(NSError)
}


/// Class for reifying a target of the `Target` enum unto a concrete `Endpoint`.
open class Endpoint<Target> {
    public typealias SampleResponseClosure = () -> EndpointSampleResponse

    open let URL: String
    open let method: Moya.Method
    open let sampleResponseClosure: SampleResponseClosure
    open let parameters: [String: Any]?
    open let parameterEncoding: Moya.ParameterEncoding
    open let httpHeaderFields: [String: String]?

    /// Main initializer for `Endpoint`.
    public init(URL: String,
        sampleResponseClosure: @escaping SampleResponseClosure,
        method: Moya.Method = Moya.Method.GET,
        parameters: [String: Any]? = nil,
        parameterEncoding: Moya.ParameterEncoding = URLEncoding(),
        httpHeaderFields: [String: String]? = nil) {

        self.URL = URL
        self.sampleResponseClosure = sampleResponseClosure
        self.method = method
        self.parameters = parameters
        self.parameterEncoding = parameterEncoding
        self.httpHeaderFields = httpHeaderFields
    }

    /// Convenience method for creating a new `Endpoint` with the same properties as the receiver, but with added parameters.
    open func endpointByAddingParameters(_ parameters: [String: Any]) -> Endpoint<Target> {
        return endpointByAdding(parameters: parameters)
    }

    /// Convenience method for creating a new `Endpoint` with the same properties as the receiver, but with added HTTP header fields.
    open func endpointByAddingHTTPHeaderFields(_ httpHeaderFields: [String: String]) -> Endpoint<Target> {
        return endpointByAdding(httpHeaderFields: httpHeaderFields)
    }

    /// Convenience method for creating a new `Endpoint` with the same properties as the receiver, but with another parameter encoding.
    open func endpointByAddingParameterEncoding(_ newParameterEncoding: Moya.ParameterEncoding) -> Endpoint<Target> {
        return endpointByAdding(parameterEncoding: newParameterEncoding)
    }

    /// Convenience method for creating a new `Endpoint`, with changes only to the properties we specify as parameters
    open func endpointByAdding(parameters: [String: Any]? = nil, httpHeaderFields: [String: String]? = nil, parameterEncoding: Moya.ParameterEncoding? = nil)  -> Endpoint<Target> {
        let newParameters = addParameters(parameters)
        let newHTTPHeaderFields = addHTTPHeaderFields(httpHeaderFields)
        let newParameterEncoding = parameterEncoding ?? self.parameterEncoding
        return Endpoint(URL: URL, sampleResponseClosure: sampleResponseClosure, method: method, parameters: newParameters, parameterEncoding: newParameterEncoding, httpHeaderFields: newHTTPHeaderFields)
    }

    fileprivate func addParameters(_ parameters: [String: Any]?) -> [String: Any]? {
        guard let unwrappedParameters = parameters, unwrappedParameters.isEmpty == false else {
            return self.parameters
        }

        var newParameters = self.parameters ?? [String: Any]()
        unwrappedParameters.forEach { (key, value) in
            newParameters[key] = value
        }
        return newParameters
    }

    fileprivate func addHTTPHeaderFields(_ headers: [String: String]?) -> [String: String]? {
        guard let unwrappedHeaders = headers, unwrappedHeaders.isEmpty == false else {
            return self.httpHeaderFields
        }

        var newHTTPHeaderFields = self.httpHeaderFields ?? [String: String]()
        unwrappedHeaders.forEach { (key, value) in
            newHTTPHeaderFields[key] = value
        }
        return newHTTPHeaderFields
    }
}

/// Extension for converting an `Endpoint` into an `NSURLRequest`.
extension Endpoint {
    public var urlRequest: URLRequest! {
        var request: URLRequest = URLRequest(url: Foundation.URL(string: URL)!) // swiftlint:disable:this force_unwrapping
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = httpHeaderFields

        return try? parameterEncoding.encode(request, with: parameters)
    }
}

/// Required for making `Endpoint` conform to `Equatable`.
public func == <T>(lhs: Endpoint<T>, rhs: Endpoint<T>) -> Bool {
    return (lhs.urlRequest == rhs.urlRequest)
}

/// Required for using `Endpoint` as a key type in a `Dictionary`.
extension Endpoint: Equatable, Hashable {
    public var hashValue: Int {
        return (urlRequest as NSURLRequest).hash
    }
}
