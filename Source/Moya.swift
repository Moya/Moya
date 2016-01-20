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
    case Delayed(seconds: NSTimeInterval)
}

/// Protocol to define the base URL, path, method, parameters and sample data for a target.
public protocol TargetType {
    var baseURL: NSURL { get }
    var path: String { get }
    var method: Moya.Method { get }
    var parameters: [String: AnyObject]? { get }
    var sampleData: NSData { get }
}

public extension TargetType {
    var sampleData: NSData { return "".dataUsingEncoding(NSUTF8StringEncoding)! }
}

/// Protocol to define the opaque type returned from a request
public protocol Cancellable {
    func cancel()
}

/// Mark: Defaults

// These functions are default mappings to MoyaProvider's properties: endpoints, requests, manager, etc.

public func DefaultEndpointMapping<Target: TargetType>(target: Target) -> Endpoint {
    let url = target.baseURL.URLByAppendingPathComponent(target.path).absoluteString
    return Endpoint(URL: url, sampleResponseClosure: {.NetworkResponse(200, target.sampleData)}, method: target.method, parameters: target.parameters)
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

/// Mark: Stubbing

public func NeverStub<Target: TargetType>(_: Target) -> Moya.StubBehavior {
    return .Never
}

public func ImmediatelyStub<Target: TargetType>(_: Target) -> Moya.StubBehavior {
    return .Immediate
}

public func DelayedStub<Target: TargetType>(seconds: NSTimeInterval)(_: Target) -> Moya.StubBehavior {
    return .Delayed(seconds: seconds)
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
