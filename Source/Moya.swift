import Foundation
import Result

/// Closure to be executed when a request has completed.
public typealias Completion = (result: Result<Moya.Response, Moya.Error>) -> ()

public typealias ProgressBlock = (progress:Progress) -> Void

public struct Progress {
    var totalBytes:Int64
    var bytesExpected:Int64
    
    var progress:Double {
        return bytesExpected > 0 ? Double(totalBytes) / Double(bytesExpected) : 1.0
    }
    
    var completed:Bool {
        return totalBytes >= bytesExpected
    }
}

/// Represents an HTTP method.
public enum Method: String {
    case GET, POST, PUT, DELETE, OPTIONS, HEAD, PATCH, TRACE, CONNECT
}

public enum StubBehavior {
    case Never
    case Immediate
    case Delayed(seconds: NSTimeInterval)
}

public struct MultipartFormData {
    public enum FormDataProvider {
        case Data(NSData)
        case File(NSURL)
        case Stream(NSInputStream, UInt64)
    }
    
    public init(provider:FormDataProvider, name:String, fileName:String = "", mimeType:String = "") {
        self.provider = provider
        self.name = name
        self.fileName = fileName
        self.mimeType = mimeType
    }
    
    public let provider:FormDataProvider
    public let name:String
    public let fileName:String
    public let mimeType:String
}

public protocol MultipartTargetType: TargetType {
    var multipartBody: [MultipartFormData] { get }
}

/// Protocol to define the base URL, path, method, parameters and sample data for a target.
public protocol TargetType {
    var baseURL: NSURL { get }
    var path: String { get }
    var method: Moya.Method { get }
    var parameters: [String: AnyObject]? { get }
    var sampleData: NSData { get }
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
    
    public let trackInflights:Bool
    
    public private(set) var inflightRequests = Dictionary<Endpoint<Target>, [Moya.Completion]>()
    
    /// Initializes a provider.
    public init(endpointClosure: EndpointClosure = MoyaProvider.DefaultEndpointMapping,
        requestClosure: RequestClosure = MoyaProvider.DefaultRequestMapping,
        stubClosure: StubClosure = MoyaProvider.NeverStub,
        manager: Manager = MoyaProvider<Target>.DefaultAlamofireManager(),
        plugins: [PluginType] = [],
        trackInflights:Bool = false) {
            
            self.endpointClosure = endpointClosure
            self.requestClosure = requestClosure
            self.stubClosure = stubClosure
            self.manager = manager
            self.plugins = plugins
            self.trackInflights = trackInflights
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
        
        if trackInflights {
            objc_sync_enter(self)
            var inflightCompletionBlocks = self.inflightRequests[endpoint]
            inflightCompletionBlocks?.append(completion)
            self.inflightRequests[endpoint] = inflightCompletionBlocks
            objc_sync_exit(self)
            
            if inflightCompletionBlocks != nil {
                return cancellableToken
            } else {
                objc_sync_enter(self)
                self.inflightRequests[endpoint] = [completion]
                objc_sync_exit(self)
            }
        }

        
        let performNetworking = { (request: NSURLRequest) in
            if cancellableToken.isCancelled { return }
            
            switch stubBehavior {
            case .Never:
                cancellableToken.innerCancellable = self.sendRequest(target, request: request, completion: { result in
                    
                    if self.trackInflights {
                        self.inflightRequests[endpoint]?.forEach({ $0(result: result) })
                        
                        objc_sync_enter(self)
                        self.inflightRequests.removeValueForKey(endpoint)
                        objc_sync_exit(self)
                    } else {
                        completion(result: result)
                    }
                })
            default:
                cancellableToken.innerCancellable = self.stubRequest(target, request: request, completion: { result in
                    if self.trackInflights {
                        self.inflightRequests[endpoint]?.forEach({ $0(result: result) })
                        
                        objc_sync_enter(self)
                        self.inflightRequests.removeValueForKey(endpoint)
                        objc_sync_exit(self)
                    } else {
                        completion(result: result)
                    }
                }, endpoint: endpoint, stubBehavior: stubBehavior)
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

public extension MoyaProvider where Target:MultipartTargetType {
    /// Designated request-making method. Returns a Cancellable token to cancel the request later.
    public func request(target: Target, progress: Moya.ProgressBlock? = nil, completion: Moya.Completion) -> Cancellable {
        let multipart = target as MultipartTargetType
        let endpoint = self.endpoint(target)
        let stubBehavior = self.stubClosure(target)
        var cancellableToken = CancellableWrapper()
        
        let performNetworking = { (request: NSURLRequest) in
            if cancellableToken.isCancelled { return }
            
            switch stubBehavior {
            case .Never:
                if multipart.multipartBody.count == 0 {
                    cancellableToken.innerCancellable = self.sendRequest(target, request: request, completion: completion)
                } else {
                    cancellableToken = self.sendUpload(target, request:request, multipartBody:multipart.multipartBody, progress:progress, completion:completion)
                }
            default:
                cancellableToken.innerCancellable = self.stubRequest(target, request: request, completion: completion, endpoint: endpoint, stubBehavior: stubBehavior)
            }
        }
        
        requestClosure(endpoint, performNetworking)
        
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

    public final class func DelayedStub(seconds: NSTimeInterval) -> (Target) -> Moya.StubBehavior {
        return { _ in return .Delayed(seconds: seconds) }
    }
}

internal extension MoyaProvider {
    
    private func sendUpload(target: Target, request:NSURLRequest, multipartBody:[MultipartFormData], progress: Moya.ProgressBlock? = nil, completion: Moya.Completion) -> CancellableWrapper {
        var cancellable = CancellableWrapper()
        let plugins = self.plugins
        
        let multipartFormData = { (form:RequestMultipartFormData) -> Void in
            for bodyPart in multipartBody {
                switch bodyPart.provider {
                case .Data(let data):
                    form.appendBodyPart(data: data, name: bodyPart.name, fileName: bodyPart.fileName, mimeType: bodyPart.mimeType)
                case .File(let url):
                    form.appendBodyPart(fileURL: url, name: bodyPart.name, fileName: bodyPart.fileName, mimeType: bodyPart.mimeType)
                case .Stream(let stream, let length):
                    form.appendBodyPart(stream: stream, length: length, name: bodyPart.name, fileName: bodyPart.fileName, mimeType: bodyPart.mimeType)
                }
            }
            
            // Add target parameters into form body
            guard let parameters = target.parameters else { return }
            for (key, value) in parameters {
                // I don't know an easy way to transform any value to NSData ¯\_(ツ)_/¯
                form.appendBodyPart(data: "\(value)".dataUsingEncoding(NSUTF8StringEncoding)!, name: key)
            }
        }
        
        manager.upload(request, multipartFormData: multipartFormData) {(result:MultipartFormDataEncodingResult) in
            switch result {
            case .Success(let alamoRequest, _, _):
                // Give plugins the chance to alter the outgoing request
                plugins.forEach { $0.willSendRequest(alamoRequest, target: target) }
                
                // Perform the actual request
                alamoRequest
                    .progress { (bytesWritten, totalBytesWritten, totalBytesExpected) in
                        progress?(progress:Progress(totalBytes: totalBytesWritten, bytesExpected: totalBytesExpected))
                    }
                    .response { (_, response: NSHTTPURLResponse?, data: NSData?, error: NSError?) -> () in
                        let result = convertResponseToResult(response, data: data, error: error)
                        // Inform all plugins about the response
                        plugins.forEach { $0.didReceiveResponse(result, target: target) }
                        completion(result: result)
                }
                
                alamoRequest.resume()
                
                cancellable.innerCancellable = CancellableToken(request: alamoRequest)
            case .Failure(let error):
                completion(result: .Failure(Moya.Error.Underlying(error)))
            }
        }
        
        return cancellable
    }
    
    func sendRequest(target: Target, request: NSURLRequest, completion: Moya.Completion) -> CancellableToken {
        let alamoRequest = manager.request(request)
        let plugins = self.plugins
        
        // Give plugins the chance to alter the outgoing request
        plugins.forEach { $0.willSendRequest(alamoRequest, target: target) }
        
        // Perform the actual request
        alamoRequest.response { (_, response: NSHTTPURLResponse?, data: NSData?, error: NSError?) -> () in
            let result = convertResponseToResult(response, data: data, error: error)
            // Inform all plugins about the response
            plugins.forEach { $0.didReceiveResponse(result, target: target) }
            completion(result: result)
        }

        alamoRequest.resume()

        return CancellableToken(request: alamoRequest)
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

public func convertResponseToResult(response: NSHTTPURLResponse?, data: NSData?, error: NSError?) ->
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

internal struct CancellableWrapper: Cancellable {
    internal var innerCancellable: CancellableToken? = nil
    
    private var isCancelled = false
    
    internal func cancel() {
        innerCancellable?.cancel()
    }
}

func encode<T>(inout value: T) -> NSData {
    return withUnsafePointer(&value) { p in
        NSData(bytes: p, length: sizeofValue(value))
    }
}
