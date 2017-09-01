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
                method: Moya.Method = Moya.Method.get,
                task: Task,
                httpHeaderFields: [String: String]? = nil) {

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

/// Extension for converting an `Endpoint` into an optional `URLRequest`.
extension Endpoint {
    /// Returns the `Endpoint` converted to a `URLRequest` if valid. Returns `nil` otherwise.
    public var urlRequest: URLRequest? {
        guard let requestURL = Foundation.URL(string: url) else { return nil }

        var request = URLRequest(url: requestURL)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = httpHeaderFields

        switch task {
        case .requestPlain, .uploadFile, .uploadMultipart, .downloadDestination:
            return request
        case .requestData(let data):
            request.httpBody = data
            return request
        case let .requestParameters(parameters, parameterEncoding):
            return try? parameterEncoding.encode(request, with: parameters)
        case let .uploadCompositeMultipart(_, urlParameters):
            return try? URLEncoding(destination: .queryString).encode(request, with: urlParameters)
        case let .downloadParameters(parameters, parameterEncoding, _):
            return try? parameterEncoding.encode(request, with: parameters)
        case let .requestCompositeData(bodyData: bodyData, urlParameters: urlParameters):
            request.httpBody = bodyData
            return try? URLEncoding(destination: .queryString).encode(request, with: urlParameters)
        case let .requestCompositeParameters(bodyParameters: bodyParameters, bodyEncoding: bodyParameterEncoding, urlParameters: urlParameters):
            if bodyParameterEncoding is URLEncoding { fatalError("URLEncoding is disallowed as bodyEncoding.") }
            guard let bodyfulRequest = try? bodyParameterEncoding.encode(request, with: bodyParameters) else { return nil }
            return try? URLEncoding(destination: .queryString).encode(bodyfulRequest, with: urlParameters)
        }
    }
}

/// Required for using `Endpoint` as a key type in a `Dictionary`.
extension Endpoint: Equatable, Hashable {
    public var hashValue: Int {
        return urlRequest?.hashValue ?? url.hashValue
    }

    public static func == <T>(lhs: Endpoint<T>, rhs: Endpoint<T>) -> Bool {
        if lhs.urlRequest != nil, rhs.urlRequest == nil { return false }
        if lhs.urlRequest == nil, rhs.urlRequest != nil { return false }
        if lhs.urlRequest == nil, rhs.urlRequest == nil { return lhs.hashValue == rhs.hashValue }
        return (lhs.urlRequest == rhs.urlRequest)
    }
}
