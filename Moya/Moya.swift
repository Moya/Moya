import Foundation
import Alamofire

/// General-purpose class to store some enums and class funcs.
public class Moya {

    /// Closure to be executed when a request has completed.
    public typealias Completion = (data: NSData?, statusCode: Int?, response: NSURLResponse?, error: ErrorType?) -> ()

    /// Network activity change notification type.
    public enum NetworkActivityChangeType {
        case Began, Ended
    }

    /// Network activity change notification closure typealias.
    /// Explicitly outside the MoyaProvider type since it doesn't touch the Target generic.
    public typealias NetworkActivityClosure = (change: NetworkActivityChangeType) -> ()

    /// Represents an HTTP method.
    public enum Method {
        case GET, POST, PUT, DELETE, OPTIONS, HEAD, PATCH, TRACE, CONNECT

        func method() -> Alamofire.Method {
            switch self {
            case .GET:
                return .GET
            case .POST:
                return .POST
            case .PUT:
                return .PUT
            case .DELETE:
                return .DELETE
            case .HEAD:
                return .HEAD
            case .OPTIONS:
                return .OPTIONS
            case PATCH:
                return .PATCH
            case TRACE:
                return .TRACE
            case .CONNECT:
                return .CONNECT
            }
        }
    }

    /// Choice of parameter encoding.
    public enum ParameterEncoding {
        case URL
        case JSON
        case PropertyList(NSPropertyListFormat, NSPropertyListWriteOptions)
        case Custom((URLRequestConvertible, [String: AnyObject]?) -> (NSMutableURLRequest, NSError?))

        func parameterEncoding() -> Alamofire.ParameterEncoding {
            switch self {
            case .URL:
                return .URL
            case .JSON:
                return .JSON
            case .PropertyList(let format, let options):
                return .PropertyList(format, options)
            case .Custom(let closure):
                return .Custom(closure)
            }
        }
    }

    public enum StubBehavior {
        case Never
        case Immediate
        case Delayed(seconds: NSTimeInterval)
    }
}

/// Protocol to define the base URL, path, method, parameters and sample data for a target.
public protocol MoyaTarget {
    var baseURL: NSURL { get }
    var path: String { get }
    var method: Moya.Method { get }
    var parameters: [String: AnyObject]? { get }
    var sampleData: NSData { get }
}

/// Protocol to define the opaque type returned from a request
public protocol Cancellable {
    func cancel()
}

/// Internal token that can be used to cancel requests
struct CancellableToken: Cancellable {
    let cancelAction: () -> Void

    func cancel() {
        cancelAction()
    }
}

struct CancellableWrapper: Cancellable {
    var innerCancellable: CancellableToken? = nil

    private var isCancelled = false

    func cancel() {
        innerCancellable?.cancel()
    }
}

/// Request provider class. Requests should be made through this class only.
public class MoyaProvider<Target: MoyaTarget> {

    /// Closure that defines the endpoints for the provider.
    public typealias EndpointClosure = Target -> Endpoint<Target>

    /// Closure that resolves an Endpoint into an NSURLRequest.
    public typealias RequestClosure = (Endpoint<Target>, NSURLRequest -> Void) -> Void

    /// Closure that decides if/how a request should be stubbed.
    public typealias StubClosure = Target -> Moya.StubBehavior

    public typealias CredentialClosure = Target -> NSURLCredential?

    public let endpointClosure: EndpointClosure
    public let requestClosure: RequestClosure
    public let stubClosure: StubClosure
    public let credentialClosure: CredentialClosure?

    public let networkActivityClosure: Moya.NetworkActivityClosure?
    public let manager: Manager

    /// Initializes a provider.
    public init(endpointClosure: EndpointClosure = MoyaProvider.DefaultEndpointMapping,
        requestClosure: RequestClosure = MoyaProvider.DefaultRequestMapping,
        stubClosure: StubClosure = MoyaProvider.NeverStub,
        networkActivityClosure: Moya.NetworkActivityClosure? = nil,
        credentialClosure: CredentialClosure? = nil,
        manager: Manager = Alamofire.Manager.sharedInstance) {

        self.endpointClosure = endpointClosure
        self.requestClosure = requestClosure
        self.stubClosure = stubClosure
        self.networkActivityClosure = networkActivityClosure
        self.credentialClosure = credentialClosure
        self.manager = manager
    }

    /// Returns an Endpoint based on the token, method, and parameters by invoking the endpointsClosure.
    public func endpoint(token: Target) -> Endpoint<Target> {
        return endpointClosure(token)
    }

    /// Designated request-making method. Returns a Cancellable token to cancel the request later.
    public func request(token: Target, completion: Moya.Completion) -> Cancellable {
        let endpoint = self.endpoint(token)
        let stubBehavior = self.stubClosure(token)

        let credential = credentialClosure?(token)

        var cancellableToken = CancellableWrapper()

        let performNetworking = { (request: NSURLRequest) in
            if cancellableToken.isCancelled { return }

            switch stubBehavior {
            case .Never:
                cancellableToken.innerCancellable = self.sendRequest(request, credential: credential, completion: completion)
            default:
                cancellableToken.innerCancellable = self.stubRequest(request, completion: completion, endpoint: endpoint, stubBehavior: stubBehavior)
            }
        }

        requestClosure(endpoint, performNetworking)

        return cancellableToken
    }
}

/// Mark: Defaults

public extension MoyaProvider {

    // These functions are default mappings to endpoings and requests.

    public class func DefaultEndpointMapping(target: Target) -> Endpoint<Target> {
        let url = target.baseURL.URLByAppendingPathComponent(target.path).absoluteString
        return Endpoint(URL: url, sampleResponse: .Success(200, {target.sampleData}), method: target.method, parameters: target.parameters)
    }

    public class func DefaultRequestMapping(endpoint: Endpoint<Target>, closure: NSURLRequest -> Void) {
        return closure(endpoint.urlRequest)
    }
}

/// Mark: Stubbing

public extension MoyaProvider {

    // Swift won't let us put the StubBehavior enum inside the provider class, so we'll
    // at least add some class functions to allow easy access to common stubbing closures.

    public class func NeverStub(_: Target) -> Moya.StubBehavior {
        return .Never
    }

    public class func ImmediatelyStub(_: Target) -> Moya.StubBehavior {
        return .Immediate
    }

    public class func DelayedStub(seconds: NSTimeInterval)(_: Target) -> Moya.StubBehavior {
        return .Delayed(seconds: seconds)
    }
}

private extension MoyaProvider {

    func sendRequest(request: NSURLRequest, credential: NSURLCredential?, completion: Moya.Completion) -> CancellableToken {
        networkActivityClosure?(change: .Began)

        // We need to keep a reference to the closure without a reference to ourself.
        let networkActivityCallback = networkActivityClosure

        var request = manager.request(request)
        
        if let cred = credential {
            request = request.authenticate(usingCredential: cred)
        }
        
        request.response { (request: NSURLRequest?, response: NSHTTPURLResponse?, data: NSData?, error: ErrorType?) -> () in

                networkActivityCallback?(change: .Ended)

                // Alamofire always sends the data param as an NSData? type, but we'll
                // add a check just in case something changes in the future.
                let statusCode = response?.statusCode
                if let data = data {
                    completion(data: data, statusCode: statusCode, response: response, error: error)
                } else {
                    completion(data: nil, statusCode: statusCode, response: response, error: error)
                }
        }

        return CancellableToken {
            request.cancel()
        }
    }

    func stubRequest(request: NSURLRequest, completion: Moya.Completion, endpoint: Endpoint<Target>, stubBehavior: Moya.StubBehavior) -> CancellableToken {
        var canceled = false
        let cancellableToken = CancellableToken { canceled = true }

        // Begin network activity closure
        networkActivityClosure?(change: .Began)

        let stub: () -> () = {
            self.networkActivityClosure?(change: .Ended)

            if (canceled) {
                completion(data: nil, statusCode: nil, response: nil, error: NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled, userInfo: nil))
                return
            }

            switch endpoint.sampleResponse.evaluate() {
            case .Success(let statusCode, let data):
                completion(data: data(), statusCode: statusCode, response:nil, error: nil)
            case .Error(let statusCode, let error, let data):
                completion(data: data?(), statusCode: statusCode, response:nil, error: error)
            case .Closure:
                break  // the `evaluate()` method will never actually return a .Closure
            }
        }

        switch stubBehavior {
        case .Immediate:
            stub()
        case .Delayed(let delay):
            let killTimeOffset = Int64(CDouble(delay) * CDouble(NSEC_PER_SEC))
            let killTime = dispatch_time(DISPATCH_TIME_NOW, killTimeOffset)
            dispatch_after(killTime, dispatch_get_main_queue()) {
                stub()
            }
        case .Never:
            fatalError("Method called to stub request when stubbing is disabled.")
        }

        return cancellableToken
    }
}
