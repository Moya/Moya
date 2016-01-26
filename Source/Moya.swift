import Foundation
import Result

/// Closure to be executed when a request has completed.
public typealias Completion = (result: Result<Moya.Response, Moya.Error>) -> ()

/// Represents an HTTP method.
public enum Method: String {
    case GET, POST, PUT, DELETE, OPTIONS, HEAD, PATCH, TRACE, CONNECT
}

public enum StubBehavior {
    case Never
    case Immediate
    case Delayed(NSTimeInterval)
}

/// Protocol to define the base URL, path, method, parameters and sample data for a target.
public protocol TargetType {
    var baseURL: NSURL { get }
    var path: String { get }
    var method: Moya.Method { get }
    var parameters: [String: AnyObject]? { get }
    var parameterEncoding: ParameterEncoding { get }
    var sampleData: NSData { get }

    func toEndpoint() -> Endpoint
}

public extension TargetType {
    func toEndpoint() -> Endpoint {
        let url = self.baseURL.URLByAppendingPathComponent(self.path).absoluteString
        return Endpoint(URL: url, sampleResponseClosure: {.NetworkResponse(200, self.sampleData)}, method: self.method, parameters: self.parameters, parameterEncoding: parameterEncoding)
    }
}

/// TODO: Compatibility for existing test cases
public extension TargetType {
    var parameterEncoding: ParameterEncoding { return .URL }
}

public protocol MoyaProviderBackendType {
    func request(target: TargetType,
                 endpoint: Endpoint,
                 request: NSURLRequest,
                 plugins: [PluginType],
                 completion: Moya.Completion) -> CancellableToken

    /// TODO: Just keeping test cases no need to change
    var manager: Manager { get }
}

/// Protocol to define the opaque type returned from a request
public protocol Cancellable {
    func cancel()
}

/// Mark: Defaults

// These functions are default mappings to MoyaProvider's properties: endpoints, requests, manager, etc.

public func DefaultCommonEndpointMapping(target: TargetType) -> Endpoint {
    return target.toEndpoint()
}

public func DefaultEndpointMapping<Target: TargetType>(target: Target) -> Endpoint {
    return target.toEndpoint()
}

public func DefaultRequestMapping(endpoint: Endpoint, closure: NSURLRequest -> Void) {
    return closure(endpoint.urlRequest)
}

public func DefaultAlamofireManager() -> Manager {
    let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
    configuration.HTTPAdditionalHeaders = Manager.defaultHTTPHeaders

    let manager = Manager(configuration: configuration)
    manager.startRequestsImmediately = false
    return manager
}

internal func convertResponseToResult(response: NSHTTPURLResponse?, data: NSData?, error: NSError?) ->
    Result<Moya.Response, Moya.Error> {
    switch (response, data, error) {
    case let (.Some(response), .Some(data), .None):
        let response = Moya.Response(statusCode: response.statusCode, data: data, response: response)
        return .Success(response)
    case let (_, _, .Some(error)):
        let error = Moya.Error.Underlying(error)
        return .Failure(error)
    default:
        let error = Moya.Error.Underlying(NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: nil))
        return .Failure(error)
    }
}
