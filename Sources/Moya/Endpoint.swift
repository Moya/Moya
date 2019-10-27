import Foundation

/// Used for stubbing responses.
public enum EndpointSampleResponse {

    /// The network returned a response, including status code and data.
    case networkResponse(Int, Data)

    /// The network returned response which can be fully customized.
    case response(HTTPURLResponse, Data)

    /// The network failed to send the request, or failed to retrieve a response (eg a timeout).
    case networkError(NSError)
}

/// Class for reifying a target of the `Target` enum unto a concrete `Endpoint`.
/// - Note: As of Moya 11.0.0 Endpoint is no longer generic.
///   Existing code should work as is after removing the generic.
///   See #1529 and #1524 for the discussion.
open class Endpoint {
    public typealias SampleResponseClosure = () -> EndpointSampleResponse

    /// A string representation of the URL for the request.
    public let url: String

    /// A closure responsible for returning an `EndpointSampleResponse`.
    public let sampleResponseClosure: SampleResponseClosure

    /// The HTTP method for the request.
    public let method: Moya.Method

    /// The `Task` for the request.
    public let task: Task

    /// The HTTP header fields for the request.
    public let httpHeaderFields: [String: String]?

    public init(url: String,
                sampleResponseClosure: @escaping SampleResponseClosure,
                method: Moya.Method,
                task: Task,
                httpHeaderFields: [String: String]?) {

        self.url = url
        self.sampleResponseClosure = sampleResponseClosure
        self.method = method
        self.task = task
        self.httpHeaderFields = httpHeaderFields
    }

    /// Convenience method for creating a new `Endpoint` with the same properties as the receiver, but with added HTTP header fields.
    open func adding(newHTTPHeaderFields: [String: String]) -> Endpoint {
        Endpoint(url: url, sampleResponseClosure: sampleResponseClosure, method: method, task: task, httpHeaderFields: add(httpHeaderFields: newHTTPHeaderFields))
    }

    /// Convenience method for creating a new `Endpoint` with the same properties as the receiver, but with replaced `task` parameter.
    open func replacing(task: Task) -> Endpoint {
        Endpoint(url: url, sampleResponseClosure: sampleResponseClosure, method: method, task: task, httpHeaderFields: httpHeaderFields)
    }

    fileprivate func add(httpHeaderFields headers: [String: String]?) -> [String: String]? {
        guard let unwrappedHeaders = headers, unwrappedHeaders.isEmpty == false else {
            return self.httpHeaderFields
        }

        var newHTTPHeaderFields = self.httpHeaderFields ?? [:]
        unwrappedHeaders.forEach { key, value in
            newHTTPHeaderFields[key] = value
        }
        return newHTTPHeaderFields
    }
}

/// Extension for converting an `Endpoint` into a `URLRequest`.
public extension Endpoint {
    /// Returns the `Endpoint` converted to a `URLRequest` if valid. Throws an error otherwise.
    func urlRequest() throws -> URLRequest {
        guard let requestURL = Foundation.URL(string: url) else {
            throw MoyaError.requestMapping(url)
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = httpHeaderFields

        //Encode params
        try task.allParameters().forEach { tuple in
            let encodable = tuple.0
            let encoder = tuple.1
            request = try encoder.encode(AnyEncodable(encodable), into: request)
        }

        return request
    }
}

/// Required for using `Endpoint` as a key type in a `Dictionary`.
extension Endpoint: Equatable, Hashable {
    public func hash(into hasher: inout Hasher) {
        guard let request = try? urlRequest() else {
            hasher.combine(url)
            return
        }
        hasher.combine(request)
    }

    /// Note: If both Endpoints fail to produce a URLRequest the comparison will
    /// fall back to comparing each Endpoint's hashValue.
    public static func == (lhs: Endpoint, rhs: Endpoint) -> Bool {
        let lhsRequest = try? lhs.urlRequest()
        let rhsRequest = try? rhs.urlRequest()
        if lhsRequest != nil, rhsRequest == nil { return false }
        if lhsRequest == nil, rhsRequest != nil { return false }
        if lhsRequest == nil, rhsRequest == nil { return lhs.hashValue == rhs.hashValue }
        return (lhsRequest == rhsRequest)
    }
}
