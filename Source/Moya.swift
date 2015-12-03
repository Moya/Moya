import Foundation
import Alamofire

/// Closure to be executed when a request has completed.
public typealias Completion = (result: Moya.Result<Moya.Response, Moya.Error>) -> ()

/// Represents an HTTP method.
public enum Method: String {
    case GET, POST, PUT, DELETE, OPTIONS, HEAD, PATCH, TRACE, CONNECT
}

/// Choice of parameter encoding.
public enum ParameterEncoding {
    case URL
    case JSON
    case PropertyList(NSPropertyListFormat, NSPropertyListWriteOptions)
    case Custom((URLRequestConvertible, [String: AnyObject]?) -> (NSMutableURLRequest, NSError?))
    
    internal var toAlamofire: Alamofire.ParameterEncoding {
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
public class MoyaProvider<Target: TargetType> {
    
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
    public let plugins: [PluginType]
    
    /// Initializes a provider.
    public init(endpointClosure: EndpointClosure = MoyaProvider.DefaultEndpointMapping,
        requestClosure: RequestClosure = MoyaProvider.DefaultRequestMapping,
        stubClosure: StubClosure = MoyaProvider.NeverStub,
        manager: Manager = Alamofire.Manager.sharedInstance,
        plugins: [PluginType] = []) {
            
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

public extension MoyaProvider {
    
    // These functions are default mappings to endpoings and requests.
    
    public final class func DefaultEndpointMapping(target: Target) -> Endpoint<Target> {
        let url = target.baseURL.URLByAppendingPathComponent(target.path).absoluteString
        return Endpoint(URL: url, sampleResponseClosure: {.NetworkResponse(200, target.sampleData)}, method: target.method, parameters: target.parameters)
    }
    
    public final class func DefaultRequestMapping(endpoint: Endpoint<Target>, closure: NSURLRequest -> Void) {
        return closure(endpoint.urlRequest)
    }
}

/// Mark: Stubbing

public extension MoyaProvider {
    
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

internal extension MoyaProvider {
    
    func sendRequest(target: Target, request: NSURLRequest, completion: Moya.Completion) -> CancellableToken {
        let request = manager.request(request)
        let plugins = self.plugins
        
        // Give plugins the chance to alter the outgoing request
        plugins.forEach { $0.willSendRequest(request, target: target) }
        
        // Perform the actual request
        let alamoRequest = request.response { (_, response: NSHTTPURLResponse?, data: NSData?, error: NSError?) -> () in
            let result = convertResponseToResult(response, data: data, error: error)
            // Inform all plugins about the response
            plugins.forEach { $0.didReceiveResponse(result, target: target) }
            completion(result: result)
        }
        
        return CancellableToken(request: alamoRequest)
    }
    
    /// Creates a function which, when called, executes the appropriate stubbing behavior for the given parameters.
    internal final func createStubFunction(token: CancellableToken, forTarget target: Target, withCompletion completion: Moya.Completion, endpoint: Endpoint<Target>, plugins: [PluginType]) -> (() -> ()) {
        return {
            if (token.canceled) {
                let error = Moya.Error.Underlying(NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled, userInfo: nil))
                plugins.forEach { $0.didReceiveResponse(Moya.Result(failure: error), target: target) }
                completion(result: Result(failure: error))
                return
            }
            
            switch endpoint.sampleResponseClosure() {
            case .NetworkResponse(let statusCode, let data):
                let response = Moya.Response(statusCode: statusCode, data: data, response: nil)
                plugins.forEach { $0.didReceiveResponse(Moya.Result(success: response), target: target) }
                completion(result: Moya.Result(success: response))
            case .NetworkError(let error):
                let error = Moya.Error.Underlying(error)
                plugins.forEach { $0.didReceiveResponse(Moya.Result(failure: error), target: target) }
                completion(result: Moya.Result(failure: error))
            }
        }
    }
    
    /// Notify all plugins that a stub is about to be performed. You must call this if overriding `stubRequest`.
    internal final func notifyPluginsOfImpendingStub(request: NSURLRequest, target: Target) {
        let request = manager.request(request)
        plugins.forEach { $0.willSendRequest(request, target: target) }
    }
}

private func convertResponseToResult(response: NSHTTPURLResponse?, data: NSData?, error: NSError?) -> Moya.Result<Moya.Response, Moya.Error> {
    switch (response, data, error) {
    case let (.Some(response), .Some(data), .None):
        let response = Moya.Response(statusCode: response.statusCode, data: data, response: response)
        return Moya.Result(success: response)
    case let (.None, .None, .Some(error)):
        let error = Moya.Error.Underlying(error)
        return Moya.Result(failure: error)
    default:
        let error = Moya.Error.Underlying(NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: nil))
        return Moya.Result(failure: error)
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
extension Request: RequestType { }
