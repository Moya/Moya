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
open class Endpoint<Target> {
    public typealias SampleResponseClosure = () -> EndpointSampleResponse

    open let url: String
    open let sampleResponseClosure: SampleResponseClosure
    open let method: Moya.Method
    open let task: Task
    open let httpHeaderFields: [String: String]?

    /// Main initializer for `Endpoint`.
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
    open func adding(newHTTPHeaderFields: [String: String]) -> Endpoint<Target> {
        return Endpoint(url: url, sampleResponseClosure: sampleResponseClosure, method: method, task: task, httpHeaderFields: add(httpHeaderFields: newHTTPHeaderFields))
    }

    /// Convenience method for creating a new `Endpoint` with the same properties as the receiver, but with replaced `task` parameter.
    open func replacing(task: Task) -> Endpoint<Target> {
        return Endpoint(url: url, sampleResponseClosure: sampleResponseClosure, method: method, task: task, httpHeaderFields: httpHeaderFields)
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
extension Endpoint {
    /// Returns the `Endpoint` converted to a `URLRequest` if valid. Throws an error otherwise.
    public func urlRequest() throws -> URLRequest {
        guard let requestURL = Foundation.URL(string: url) else {
            throw MoyaError.requestMapping(url)
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = httpHeaderFields

        switch task {
        case .requestPlain, .uploadFile, .uploadMultipart, .downloadDestination:
            return request
        case .requestData(let data):
            request.httpBody = data
            return request
        case let .requestJSONEncodable(encodable):
            return try request.encoded(encodable: encodable)
        case let .requestParameters(parameters, parameterEncoding):
            return try request.encoded(parameters: parameters, parameterEncoding: parameterEncoding)
        case let .uploadCompositeMultipart(_, urlParameters):
            let parameterEncoding = URLEncoding(destination: .queryString)
            return try request.encoded(parameters: urlParameters, parameterEncoding: parameterEncoding)
        case let .downloadParameters(parameters, parameterEncoding, _):
            return try request.encoded(parameters: parameters, parameterEncoding: parameterEncoding)
        case let .requestCompositeData(bodyData: bodyData, urlParameters: urlParameters):
            request.httpBody = bodyData
            let parameterEncoding = URLEncoding(destination: .queryString)
            return try request.encoded(parameters: urlParameters, parameterEncoding: parameterEncoding)
        case let .requestCompositeParameters(bodyParameters: bodyParameters, bodyEncoding: bodyParameterEncoding, urlParameters: urlParameters):
            if bodyParameterEncoding is URLEncoding { fatalError("URLEncoding is disallowed as bodyEncoding.") }
            let bodyfulRequest = try request.encoded(parameters: bodyParameters, parameterEncoding: bodyParameterEncoding)
            let urlEncoding = URLEncoding(destination: .queryString)
            return try bodyfulRequest.encoded(parameters: urlParameters, parameterEncoding: urlEncoding)
        }
    }
}

/// Required for using `Endpoint` as a key type in a `Dictionary`.
extension Endpoint: Equatable, Hashable {
    public var hashValue: Int {
        let request = try? urlRequest()
        return request?.hashValue ?? url.hashValue
    }

    /// Note: If both Endpoints fail to produce a URLRequest the comparison will
    /// fall back to comparing each Endpoint's hashValue.
    public static func == <T>(lhs: Endpoint<T>, rhs: Endpoint<T>) -> Bool {
        let lhsRequest = try? lhs.urlRequest()
        let rhsRequest = try? rhs.urlRequest()
        if lhsRequest != nil, rhsRequest == nil { return false }
        if lhsRequest == nil, rhsRequest != nil { return false }
        if lhsRequest == nil, rhsRequest == nil { return lhs.hashValue == rhs.hashValue }
        return (lhsRequest == rhsRequest)
    }
}
