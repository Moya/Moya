import Foundation
import Result

/// Closure to be executed when a request has completed.
public typealias Completion = (result: Result<Moya.Response, Moya.Error>) -> ()

/// Closure for providing upload/download progress
public typealias Progress = (bytesSent: Int64, totalBytesSent: Int64, totalBytesExpected: Int64) -> ()

/// Represents an HTTP method.
public enum Method: String {
    case GET, POST, PUT, DELETE, OPTIONS, HEAD, PATCH, TRACE, CONNECT
}

public enum StubBehavior {
    case Never
    case Immediate
    case Delayed(seconds: NSTimeInterval)
}

public enum TargetRequestType {
    case Request
    case Upload
}

public enum UploadType {
    case File(NSURL)
    case Data(NSData)
    case Stream(NSInputStream)
    case Multipart(MultipartFormData -> ())
}

/// Protocol to define the base URL, path, method, parameters and sample data for a target.
public protocol TargetType {
    var baseURL: NSURL { get }
    var path: String { get }
    var method: Moya.Method { get }
    var parameters: [String: AnyObject]? { get }
    var sampleData: NSData { get }
    
    var requestType: TargetRequestType { get }
    var uploadType: UploadType? { get }
}

extension TargetType {
    public var requestType: TargetRequestType {
        return .Request
    }
    
    public var uploadType: UploadType? {
        return nil
    }
}

public enum StructTarget: TargetType {
    case Struct(TargetType)

    public init(_ target: TargetType) {
        self = StructTarget.Struct(target)
    }

    public var path: String {
        return target.path
    }

    public var baseURL: NSURL {
        return target.baseURL
    }

    public var method: Moya.Method {
        return target.method
    }

    public var parameters: [String: AnyObject]? {
        return target.parameters
    }

    public var sampleData: NSData {
        return target.sampleData
    }

    public var target: TargetType {
        switch self {
        case .Struct(let t): return t
        }
    }
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
        manager: Manager = MoyaProvider<Target>.DefaultAlamofireManager(),
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
    public func request(target: Target, progress: Moya.Progress? = nil, completion: Moya.Completion) -> Cancellable {
        let endpoint = self.endpoint(target)
        let stubBehavior = self.stubClosure(target)
        
        let (cancellableToken, performNetworking) = target.requestType == .Request ? self.performRequest(endpoint, target: target, stubBehavior: stubBehavior, completion: completion) : self.performUpload(endpoint, target: target, stubBehavior: stubBehavior, progress: progress, completion: completion)
        
        requestClosure(endpoint, performNetworking)
        
        return cancellableToken
    }
    
    private func performRequest(endpoint: Endpoint<Target>, target: Target, stubBehavior: StubBehavior, completion: Moya.Completion) -> (token: Cancellable, networkingRequest: NSURLRequest -> ()) {
        var cancellableToken = CancellableWrapper()
        
        return (cancellableToken, { (request: NSURLRequest) in
            if cancellableToken.isCancelled { return }
            
            switch stubBehavior {
            case .Never:
                cancellableToken.innerCancellable = self.sendRequest(target, request: request, completion: completion)
            default:
                cancellableToken.innerCancellable = self.stubRequest(target, request: request, completion: completion, endpoint: endpoint, stubBehavior: stubBehavior)
            }
        })
    }
    
    private func performUpload(endpoint: Endpoint<Target>, target: Target, stubBehavior: StubBehavior, progress: Moya.Progress? = nil, completion: Moya.Completion) -> (token: Cancellable, networkingRequest: NSURLRequest -> ()) {
        var cancellableToken = CancellableWrapper()
        
        return (cancellableToken, { (request: NSURLRequest) in
            if cancellableToken.isCancelled { return }
            
            guard let uploadType = target.uploadType
            else {
                cancellableToken.cancel()
                return
            }
            
            let sendOrStubRequest = { (request: Request) in
                switch stubBehavior {
                case .Never:
                    cancellableToken.innerCancellable = self.sendAlamofireRequest(target, request: request, progress: progress, completion: completion)
                default:
                    cancellableToken.innerCancellable = self.stubRequest(target, request: request.request!, completion: completion, endpoint: endpoint, stubBehavior: stubBehavior)
                }
            }
            
            var alamofireRequest: Request?
            switch uploadType {
            case .File(let fileURL):
                alamofireRequest = self.manager.upload(request, file: fileURL)
            case .Data(let data):
                alamofireRequest = self.manager.upload(request, data: data)
            case .Stream(let inputStream):
                alamofireRequest = self.manager.upload(request, stream: inputStream)
            default:
                break
            }
            
            if let alamofireRequest = alamofireRequest {
                sendOrStubRequest(alamofireRequest)
            } else if case let .Multipart(multipartFormData) = uploadType {
                self.manager.upload(
                    request,
                    multipartFormData: multipartFormData,
                    encodingCompletion: { result in
                        /// Ensure that the request is cancelled if the token is cancelled
                        /// after encoding.
                        if cancellableToken.isCancelled { return }
                        
                        switch result {
                        case .Success(let encodedRequest, _, _):
                            sendOrStubRequest(encodedRequest)
                        case .Failure(let error):
                            completion(result: .Failure(Moya.Error.Underlying(error)))
                        }
                    }
                )
            }
        })
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
    
    // These functions are default mappings to MoyaProvider's properties: endpoints, requests, manager, etc.
    
    public final class func DefaultEndpointMapping(target: Target) -> Endpoint<Target> {
        let url = target.baseURL.URLByAppendingPathComponent(target.path).absoluteString
        return Endpoint(URL: url, sampleResponseClosure: {.NetworkResponse(200, target.sampleData)}, method: target.method, parameters: target.parameters)
    }
    
    public final class func DefaultRequestMapping(endpoint: Endpoint<Target>, closure: NSURLRequest -> Void) {
        return closure(endpoint.urlRequest)
    }

    public final class func DefaultAlamofireManager() -> Manager {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.HTTPAdditionalHeaders = Manager.defaultHTTPHeaders

        let manager = Manager(configuration: configuration)
        manager.startRequestsImmediately = false
        return manager
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
    
    func sendRequest(target: Target, request: NSURLRequest, progress: Moya.Progress? = nil, completion: Moya.Completion) -> CancellableToken {
        return sendAlamofireRequest(target, request: manager.request(request), completion: completion)
    }
    
    func sendAlamofireRequest(target: Target, request: Request, progress: Moya.Progress? = nil, completion: Moya.Completion) -> CancellableToken {
        let plugins = self.plugins
        
        // Give plugins the chance to alter the outgoing request
        plugins.forEach { $0.willSendRequest(request, target: target) }
        
        // Add the progress block
        request.progress(progress)
        
        // Perform the actual request
        request.response { (_, response: NSHTTPURLResponse?, data: NSData?, error: NSError?) -> () in
            let result = convertResponseToResult(response, data: data, error: error)
            // Inform all plugins about the response
            plugins.forEach { $0.didReceiveResponse(result, target: target) }
            completion(result: result)
        }
        
        request.resume()
        
        return CancellableToken(request: request)
    }
    
    /// Creates a function which, when called, executes the appropriate stubbing behavior for the given parameters.
    internal final func createStubFunction(token: CancellableToken, forTarget target: Target, withCompletion completion: Moya.Completion, endpoint: Endpoint<Target>, plugins: [PluginType]) -> (() -> ()) {
        return {
            if (token.canceled) {
                let error = Moya.Error.Underlying(NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled, userInfo: nil))
                plugins.forEach { $0.didReceiveResponse(.Failure(error), target: target) }
                completion(result: .Failure(error))
                return
            }
            
            switch endpoint.sampleResponseClosure() {
            case .NetworkResponse(let statusCode, let data):
                let response = Moya.Response(statusCode: statusCode, data: data, response: nil)
                plugins.forEach { $0.didReceiveResponse(.Success(response), target: target) }
                completion(result: .Success(response))
            case .NetworkError(let error):
                let error = Moya.Error.Underlying(error)
                plugins.forEach { $0.didReceiveResponse(.Failure(error), target: target) }
                completion(result: .Failure(error))
            }
        }
    }
    
    /// Notify all plugins that a stub is about to be performed. You must call this if overriding `stubRequest`.
    internal final func notifyPluginsOfImpendingStub(request: NSURLRequest, target: Target) {
        let alamoRequest = manager.request(request)
        plugins.forEach { $0.willSendRequest(alamoRequest, target: target) }
    }
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

private struct CancellableWrapper: Cancellable {
    var innerCancellable: CancellableToken? = nil
    
    private var isCancelled = false
    
    func cancel() {
        innerCancellable?.cancel()
    }
}
