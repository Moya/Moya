import Foundation
import Result

/// Closure to be executed when a request has completed.
public typealias Completion = (result: Result<Moya.Response, Moya.Error>) -> ()

/// Closure to be executed when a request has completed.
public typealias ProgressBlock = (progress: ProgressResponse) -> Void

public struct ProgressResponse {
    public let totalBytes: Int64
    public let bytesExpected: Int64
    public let response: Response?

    init(totalBytes: Int64 = 0, bytesExpected: Int64 = 0, response: Response? = nil) {
        self.totalBytes = totalBytes
        self.bytesExpected = bytesExpected
        self.response = response
    }

    public var progress: Double {
        return bytesExpected > 0 ? min(Double(totalBytes) / Double(bytesExpected), 1.0) : 1.0
    }

    public var completed: Bool {
        return totalBytes >= bytesExpected && response != nil
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

    public init(provider: FormDataProvider, name: String, fileName: String = "", mimeType: String = "") {
        self.provider = provider
        self.name = name
        self.fileName = fileName
        self.mimeType = mimeType
    }

    public let provider: FormDataProvider
    public let name: String
    public let fileName: String
    public let mimeType: String
}

/// Protocol to define the base URL, path, method, parameters and sample data for a target.
public protocol TargetType {
    var baseURL: NSURL { get }
    var path: String { get }
    var method: Moya.Method { get }
    var parameters: [String: AnyObject]? { get }
    var sampleData: NSData { get }
    var multipartBody: [MultipartFormData]? { get }
}

extension TargetType {
    internal var isMultipartUpload: Bool {
        guard let mBody = multipartBody else { return false }
        return (method == .POST || method == .PUT) && !mBody.isEmpty
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

    public var multipartBody: [MultipartFormData]? {
        return target.multipartBody
    }

    public var target: TargetType {
        switch self {
        case .Struct(let t): return t
        }
    }
}

/// Protocol to define the opaque type returned from a request
public protocol Cancellable {
    var cancelled: Bool { get }
    func cancel()
}

/// Request provider class. Requests should be made through this class only.
public class MoyaProvider<Target: TargetType> {

    /// Closure that defines the endpoints for the provider.
    public typealias EndpointClosure = Target -> Endpoint<Target>

    /// Closure that decides if and what request should be performed
    public typealias RequestResultClosure = Result<NSURLRequest, Moya.Error> -> Void

    /// Closure that resolves an Endpoint into an RequestResult.
    public typealias RequestClosure = (Endpoint<Target>, RequestResultClosure) -> Void

    /// Closure that decides if/how a request should be stubbed.
    public typealias StubClosure = Target -> Moya.StubBehavior

    public let endpointClosure: EndpointClosure
    public let requestClosure: RequestClosure
    public let stubClosure: StubClosure
    public let manager: Manager

    /// A list of plugins
    /// e.g. for logging, network activity indicator or credentials
    public let plugins: [PluginType]

    public let trackInflights: Bool

    public private(set) var inflightRequests = Dictionary<Endpoint<Target>, [Moya.Completion]>()

    /// Initializes a provider.
    public init(endpointClosure: EndpointClosure = MoyaProvider.DefaultEndpointMapping,
        requestClosure: RequestClosure = MoyaProvider.DefaultRequestMapping,
        stubClosure: StubClosure = MoyaProvider.NeverStub,
        manager: Manager = MoyaProvider<Target>.DefaultAlamofireManager(),
        plugins: [PluginType] = [],
        trackInflights: Bool = false) {

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
        return self.request(target, queue: nil, completion: completion)
    }

    /// Designated request-making method with queue option. Returns a Cancellable token to cancel the request later.
    public func request(target: Target, queue: dispatch_queue_t?, progress: Moya.ProgressBlock? = nil, completion: Moya.Completion) -> Cancellable {
        return requestNormal(target, queue: queue, progress: progress, completion: completion)
    }

    internal func requestNormal(target: Target, queue: dispatch_queue_t?, progress: Moya.ProgressBlock?, completion: Moya.Completion) -> Cancellable {
        let endpoint = self.endpoint(target)
        let stubBehavior = self.stubClosure(target)
        let cancellableToken = CancellableWrapper()

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

        let performNetworking = { (requestResult: Result<NSURLRequest, Moya.Error>) in
            if cancellableToken.cancelled {
                self.cancelCompletion(completion, target: target)
                return
            }

            var request: NSURLRequest!

            switch requestResult {
            case .Success(let urlRequest):
                request = urlRequest
            case .Failure(let error):
                completion(result: .Failure(error))
                return
            }

            switch stubBehavior {
            case .Never:
                let networkCompletion: Moya.Completion = { result in
                    if self.trackInflights {
                        self.inflightRequests[endpoint]?.forEach({ $0(result: result) })

                        objc_sync_enter(self)
                        self.inflightRequests.removeValueForKey(endpoint)
                        objc_sync_exit(self)
                    } else {
                        completion(result: result)
                    }
                }
                if target.isMultipartUpload {
                    guard let multipartBody = target.multipartBody where !multipartBody.isEmpty else {
                        fatalError("\(target) is not a multipart upload target.")
                    }
                    cancellableToken.innerCancellable = self.sendUpload(target, request: request, queue: queue, multipartBody: multipartBody, progress: progress, completion: networkCompletion)
                }
                else {
                    cancellableToken.innerCancellable = self.sendRequest(target, request: request, queue: queue, progress: progress, completion: networkCompletion)
                }
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

    internal func cancelCompletion(completion: Moya.Completion, target: Target) {
        let error = Moya.Error.Underlying(NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled, userInfo: nil))
        plugins.forEach { $0.didReceiveResponse(.Failure(error), target: target) }
        completion(result: .Failure(error))
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

    public final class func DefaultRequestMapping(endpoint: Endpoint<Target>, closure: RequestResultClosure) {
        return closure(.Success(endpoint.urlRequest))
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

    private func sendUpload(target: Target, request: NSURLRequest, queue: dispatch_queue_t?, multipartBody: [MultipartFormData], progress: Moya.ProgressBlock? = nil, completion: Moya.Completion) -> CancellableWrapper {
        let cancellable = CancellableWrapper()

        let multipartFormData = { (form: RequestMultipartFormData) -> Void in
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

            if let parameters = target.parameters {
                parameters
                    .flatMap { (key, value) in multipartQueryComponents(key, value) }
                    .forEach { (key, value) in
                        if let data = value.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
                            form.appendBodyPart(data: data, name: key)
                        }
                }
            }
        }

        manager.upload(request, multipartFormData: multipartFormData) { (result: MultipartFormDataEncodingResult) in
            switch result {
            case .Success(let alamoRequest, _, _):
                if cancellable.cancelled {
                    self.cancelCompletion(completion, target: target)
                    return
                }
                cancellable.innerCancellable = self.sendAlamofireRequest(alamoRequest, target: target, queue: queue, progress: progress, completion: completion)
            case .Failure(let error):
                completion(result: .Failure(Moya.Error.Underlying(error as NSError)))
            }
        }

        return cancellable
    }

    private func sendRequest(target: Target, request: NSURLRequest, queue: dispatch_queue_t?, progress: Moya.ProgressBlock?, completion: Moya.Completion) -> CancellableToken {
        let alamoRequest = manager.request(request)
        return sendAlamofireRequest(alamoRequest, target: target, queue: queue, progress: progress, completion: completion)
    }

    private func sendAlamofireRequest(alamoRequest: Request, target: Target, queue: dispatch_queue_t?, progress: Moya.ProgressBlock?, completion: Moya.Completion) -> CancellableToken {
        // Give plugins the chance to alter the outgoing request
        let plugins = self.plugins
        plugins.forEach { $0.willSendRequest(alamoRequest, target: target) }

        // Perform the actual request
        if let progress = progress {
            alamoRequest
                .progress { (bytesWritten, totalBytesWritten, totalBytesExpected) in
                    let sendProgress: () -> () = {
                        progress(progress: ProgressResponse(totalBytes: totalBytesWritten, bytesExpected: totalBytesExpected))
                    }

                    if let queue = queue {
                        dispatch_async(queue, sendProgress)
                    }
                    else {
                        sendProgress()
                    }
                }
        }

        alamoRequest
            .response(queue: queue) { (_, response: NSHTTPURLResponse?, data: NSData?, error: NSError?) -> () in
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
            if token.cancelled {
                self.cancelCompletion(completion, target: target)
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

internal class CancellableWrapper: Cancellable {
    internal var innerCancellable: Cancellable = SimpleCancellable()

    var cancelled: Bool { return innerCancellable.cancelled ?? false }

    internal func cancel() {
        innerCancellable.cancel()
    }
}

internal class SimpleCancellable: Cancellable {
    var cancelled = false
    func cancel() {
        cancelled = true
    }
}

/**
 Encode parameters for multipart/form-data
 */
private func multipartQueryComponents(key: String, _ value: AnyObject) -> [(String, String)] {
    var components: [(String, String)] = []

    if let dictionary = value as? [String: AnyObject] {
        for (nestedKey, value) in dictionary {
            components += multipartQueryComponents("\(key)[\(nestedKey)]", value)
        }
    } else if let array = value as? [AnyObject] {
        for value in array {
            components += multipartQueryComponents("\(key)[]", value)
        }
    } else {
        components.append((key, "\(value)"))
    }

    return components
}
