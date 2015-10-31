import Foundation
import Alamofire

/// General-purpose class to store some enums and class funcs.
public class Moya {

    /// Closure to be executed when a request has completed.
    public typealias Completion = (data: NSData?, statusCode: Int?, response: NSURLResponse?, error: ErrorType?) -> ()

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

/// Request provider class. Requests should be made through this class only.
public class MoyaProvider<Target: MoyaTarget> {

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
    public let plugins: [Plugin<Target>]

    /// Initializes a provider.
    public init(endpointClosure: EndpointClosure = MoyaProvider.DefaultEndpointMapping,
        requestClosure: RequestClosure = MoyaProvider.DefaultRequestMapping,
        stubClosure: StubClosure = MoyaProvider.NeverStub,
        manager: Manager = Alamofire.Manager.sharedInstance,
        plugins: [Plugin<Target>] = []) {

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
    public func request(target: Target, parameters: [String:AnyObject]?, completion: Moya.Completion) -> Cancellable {
        var endpoint = self.endpoint(target)
        let stubBehavior = self.stubClosure(target)
        var cancellableToken = CancellableWrapper()
        
        if case .Some(let parameters) = parameters {
            endpoint = endpoint.endpointByAddingParameters(parameters)
        }
        
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

    /// Convenience request-making method that takes no extra endpoint parameters
    public func request(target: Target, completion: Moya.Completion) -> Cancellable {
        return request(target, parameters: nil, completion: completion)
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

private extension MoyaProvider {

    func sendRequest(target: Target, request: NSURLRequest, completion: Moya.Completion) -> CancellableToken {
        let request = manager.request(request)
        let plugins = self.plugins
        
        // Give plugins the chance to alter the outgoing request
        plugins.forEach { $0.willSendRequest(request, provider: self, target: target) }
        
        // Perform the actual request
        let alamoRequest = request.response { (_, response: NSHTTPURLResponse?, data: NSData?, error: NSError?) -> () in
            let statusCode = response?.statusCode

            // Inform all plugins about the response
            plugins.forEach { $0.didReceiveResponse(data, statusCode: statusCode, response: response, error: error, provider: self, target: target) }
            completion(data: data, statusCode: statusCode, response: response, error: error)
        }
        

        return CancellableToken(request: alamoRequest)
    }

    func stubRequest(target: Target, request: NSURLRequest, completion: Moya.Completion, endpoint: Endpoint<Target>, stubBehavior: Moya.StubBehavior) -> CancellableToken {
        var canceled = false
        let cancellableToken = CancellableToken { canceled = true }
        let request = manager.request(request)
        let plugins = self.plugins
        
        plugins.forEach { $0.willSendRequest(request, provider: self, target: target) }
        
        let stub: () -> () = {
            if (canceled) {
                let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled, userInfo: nil)
                plugins.forEach { $0.didReceiveResponse(nil, statusCode: nil, response: nil, error: error, provider: self, target: target) }
                completion(data: nil, statusCode: nil, response: nil, error: error)
                return
            }

            switch endpoint.sampleResponseClosure() {
            case .NetworkResponse(let statusCode, let data):
                plugins.forEach { $0.didReceiveResponse(data, statusCode: statusCode, response: nil, error: nil, provider: self, target: target) }
                completion(data: data, statusCode: statusCode, response: nil, error: nil)
            case .NetworkError(let error):
                plugins.forEach { $0.didReceiveResponse(nil, statusCode: nil, response: nil, error: error, provider: self, target: target) }
                completion(data: nil, statusCode: nil, response: nil, error: error)
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

/// Private token that can be used to cancel requests
private struct CancellableToken: Cancellable , CustomDebugStringConvertible{
    let cancelAction: () -> Void
    let request : Request?

    func cancel() {
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
extension Request: MoyaRequest { }
