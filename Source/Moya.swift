import Foundation
import Alamofire

/// Closure to be executed when a request has completed.
public typealias Completion = (response: Response?, error: ErrorType?) -> ()

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
/// Protocol to define the base URL, path, method, parameters and sample data for a target.
public protocol TargetType {
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

/// Request provider class. Requests should be made through this class only.
public class NetworkResourceProvider<Target: TargetType> {

    /// Closure that defines the endpoints for the provider.
    public typealias EndpointClosure = Target -> Endpoint<Target>

    /// Closure that resolves an Endpoint into an NSURLRequest.
    public typealias RequestClosure = (Endpoint<Target>, NSURLRequest -> Void) -> Void

    /// Closure that decides if/how a request should be stubbed.
    public typealias StubClosure = Target -> Moya.StubBehavior

    public let endpointClosure: EndpointClosure
    public let requestClosure: RequestClosure
    public let stubClosure: StubClosure
    public let manager: Manager
    
    /// A list of plugins
    /// e.g. for logging, network activity indicator or credentials
    public let plugins: [Plugin]

    /// Initializes a provider.
    public init(endpointClosure: EndpointClosure = NetworkResourceProvider.DefaultEndpointMapping,
        requestClosure: RequestClosure = NetworkResourceProvider.DefaultRequestMapping,
        stubClosure: StubClosure = NetworkResourceProvider.NeverStub,
        manager: Manager = Alamofire.Manager.sharedInstance,
        plugins: [Plugin] = []) {

        self.endpointClosure = endpointClosure
        self.requestClosure = requestClosure
        self.stubClosure = stubClosure
        self.manager = manager
        self.plugins = plugins
    }

    /// Returns an Endpoint based on the token, method, and parameters by invoking the endpointsClosure.
    public func endpoint(token: Target) -> Endpoint<Target> {
        return endpointClosure(token)
    }

    /// Designated request-making method. Returns a Cancellable token to cancel the request later.
    public func request(target: Target, completion: Moya.Completion) -> Cancellable {
        let endpoint = self.endpoint(target)
        let stubBehavior = self.stubClosure(target)
        var cancellableToken = CancellableWrapper()

        let performNetworking = { (request: NSURLRequest) in
            if cancellableToken.isCancelled { return }

            switch stubBehavior {
            case .Never:
                cancellableToken.innerCancellable = self.sendRequest(target, request: request, completion: completion)
            default:
                cancellableToken.innerCancellable = self.stubRequest(target, request: request, completion: completion, endpoint: endpoint, stubBehavior: stubBehavior)
            }
        }

        requestClosure(endpoint, performNetworking)

        return cancellableToken
    }

    /// When overriding this method, take care to `notifyPluginsOfImpendingStub` and to perform the stub using the `createStubFunction` method.
    /// Note: this was previously in an extension, however it must be in the original class declaration to allow subclasses to override.
    internal func stubRequest(target: Target, request: NSURLRequest, completion: Moya.Completion, endpoint: Endpoint<Target>, stubBehavior: Moya.StubBehavior) -> CancellableToken {
        let cancellableToken = CancellableToken { }
        notifyPluginsOfImpendingStub(request, target: target)
        let plugins = self.plugins
        let stub: () -> () = createStubFunction(cancellableToken, forTarget: target, withCompletion: completion, endpoint: endpoint, plugins: plugins)
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

/// Mark: Defaults

public extension NetworkResourceProvider {

    // These functions are default mappings to endpoings and requests.

    public final class func DefaultEndpointMapping(target: Target) -> Endpoint<Target> {
        let url = target.baseURL.URLByAppendingPathComponent(target.path).absoluteString
        let response = Response(statusCode: 200, data: target.sampleData)
        return Endpoint(URL: url, sampleResponseClosure: .NetworkResponse(response), method: target.method, parameters: target.parameters)
    }

    public final class func DefaultRequestMapping(endpoint: Endpoint<Target>, closure: NSURLRequest -> Void) {
        return closure(endpoint.urlRequest)
    }
}

/// Mark: Stubbing

public extension NetworkResourceProvider {

    // Swift won't let us put the StubBehavior enum inside the provider class, so we'll
    // at least add some class functions to allow easy access to common stubbing closures.

    public final class func NeverStub(_: Target) -> Moya.StubBehavior {
        return .Never
    }

    public final class func ImmediatelyStub(_: Target) -> Moya.StubBehavior {
        return .Immediate
    }

    public final class func DelayedStub(seconds: NSTimeInterval)(_: Target) -> Moya.StubBehavior {
        return .Delayed(seconds: seconds)
    }
}

internal extension NetworkResourceProvider {

    func sendRequest(target: Target, request: NSURLRequest, completion: Moya.Completion) -> CancellableToken {
        let request = manager.request(request)
        let plugins = self.plugins
        
        // Give plugins the chance to alter the outgoing request
        plugins.forEach { $0.willSendRequest(request, target: target) }
        
        // Perform the actual request
        let alamoRequest = request.response { (_, response: NSHTTPURLResponse?, data: NSData?, error: NSError?) -> () in
            let statusCode = response?.statusCode
            // Inform all plugins about the response
            plugins.forEach { $0.didReceiveResponse(data, statusCode: statusCode, response: response, error: error, target: target) }
            // Handle completion
            switch (data, response) {
            case let (.Some(d), .Some(r)):
                let response = Response(statusCode: r.statusCode, data: d, response: r)
                completion(response: response, error: error)
            default:
                completion(response: nil, error: error)
            }
        }
        

        return CancellableToken(request: alamoRequest)
    }

    /// Creates a function which, when called, executes the appropriate stubbing behavior for the given parameters.
    internal final func createStubFunction(token: CancellableToken, forTarget target: Target, withCompletion completion: Moya.Completion, endpoint: Endpoint<Target>, plugins: [Plugin]) -> (() -> ()) {
        return {
            if (token.canceled) {
                let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled, userInfo: nil)
                plugins.forEach { $0.didReceiveResponse(nil, statusCode: nil, response: nil, error: error, target: target) }
                completion(response: nil, error: error)
                return
            }

            switch endpoint.sampleResponseClosure() {
            case .NetworkResponse(let response):
                plugins.forEach { $0.didReceiveResponse(response.data, statusCode: response.statusCode, response: nil, error: nil, target: target) }
                completion(response: response, error: nil)
            case .NetworkError(let error):
                plugins.forEach { $0.didReceiveResponse(nil, statusCode: nil, response: nil, error: error, target: target) }
                completion(response: nil, error: error)
            }
        }
    }

    /// Notify all plugins that a stub is about to be performed. You must call this if overriding `stubRequest`.
    internal final func notifyPluginsOfImpendingStub(request: NSURLRequest, target: Target) {
        let request = manager.request(request)
        plugins.forEach { $0.willSendRequest(request, target: target) }
    }
}

/// Internal token that can be used to cancel requests
internal final class CancellableToken: Cancellable , CustomDebugStringConvertible{
    let cancelAction: () -> Void
    let request : Request?
    private(set) var canceled: Bool = false

    private var lock: OSSpinLock = OS_SPINLOCK_INIT

    func cancel() {
        OSSpinLockLock(&lock)
        defer { OSSpinLockUnlock(&lock) }
        guard !canceled else { return }
        canceled = true
        cancelAction()
    }

    init(action: () -> Void){
        self.cancelAction = action
        self.request = nil
    }
    
    init(request : Request){
        self.request = request
        self.cancelAction = {
             request.cancel()
        }
    }
    
    var debugDescription: String {
        guard let request = self.request else {
            return "Empty Request"
        }
        return request.debugDescription
    }
    
}

private struct CancellableWrapper: Cancellable {
    var innerCancellable: CancellableToken? = nil

    private var isCancelled = false

    func cancel() {
        innerCancellable?.cancel()
    }
}

/// Make the Alamofire Request type conform to our type, to prevent leaking Alamofire to plugins.
extension Alamofire.Request: Request { }
