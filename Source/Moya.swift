import Foundation
import Result

/// Closure to be executed when a request has completed.
public typealias Completion = (_ result: Result<Moya.Response, Moya.Error>) -> ()

/// Closure to be executed when progress changes.
public typealias ProgressBlock = (_ progress: ProgressResponse) -> Void

public struct ProgressResponse {
    public let response: Response?
    public let progressObject: Progress?

    init(progress: Progress? = nil, response: Response? = nil) {
        self.progressObject = progress
        self.response = response
    }

    public var progress: Double {
        return progressObject?.fractionCompleted ?? 1.0
    }

    public var completed: Bool {
        return progress == 1.0 && response != nil
    }
}


/// Request provider class. Requests should be made through this class only.
open class MoyaProvider<Target: TargetType> {

    /// Closure that defines the endpoints for the provider.
    public typealias EndpointClosure = (Target) -> Endpoint<Target>

    /// Closure that decides if and what request should be performed
    public typealias RequestResultClosure = (Result<URLRequest, Moya.Error>) -> Void

    /// Closure that resolves an `Endpoint` into a `RequestResult`.
    public typealias RequestClosure = (Endpoint<Target>, @escaping RequestResultClosure) -> Void

    /// Closure that decides if/how a request should be stubbed.
    public typealias StubClosure = (Target) -> Moya.StubBehavior

    open let endpointClosure: EndpointClosure
    open let requestClosure: RequestClosure
    open let stubClosure: StubClosure
    open let manager: Manager

    /// A list of plugins
    /// e.g. for logging, network activity indicator or credentials
    open let plugins: [PluginType]

    open let trackInflights: Bool

    open internal(set) var inflightRequests = Dictionary<Endpoint<Target>, [Moya.Completion]>()

    /// Initializes a provider.
    public init(endpointClosure: @escaping EndpointClosure = MoyaProvider.DefaultEndpointMapping,
        requestClosure: @escaping RequestClosure = MoyaProvider.DefaultRequestMapping,
        stubClosure: @escaping StubClosure = MoyaProvider.NeverStub,
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

    /// Returns an `Endpoint` based on the token, method, and parameters by invoking the `endpointClosure`.
    open func endpoint(_ token: Target) -> Endpoint<Target> {
        return endpointClosure(token)
    }

    /// Designated request-making method. Returns a `Cancellable` token to cancel the request later.
    @discardableResult
    open func request(_ target: Target, completion: @escaping Moya.Completion) -> Cancellable {
        return self.request(target, queue: nil, completion: completion)
    }

    /// Designated request-making method with queue option. Returns a `Cancellable` token to cancel the request later.
    @discardableResult
    open func request(_ target: Target, queue: DispatchQueue?, progress: Moya.ProgressBlock? = nil, completion: @escaping Moya.Completion) -> Cancellable {
        return requestNormal(target, queue: queue, progress: progress, completion: completion)
    }

    /// When overriding this method, take care to `notifyPluginsOfImpendingStub` and to perform the stub using the `createStubFunction` method.
    /// Note: this was previously in an extension, however it must be in the original class declaration to allow subclasses to override.
    @discardableResult
    func stubRequest(_ target: Target, request: URLRequest, completion: @escaping Moya.Completion, endpoint: Endpoint<Target>, stubBehavior: Moya.StubBehavior) -> CancellableToken {
        let cancellableToken = CancellableToken { }
        notifyPluginsOfImpendingStub(request, target: target)
        let plugins = self.plugins
        let stub: () -> () = createStubFunction(cancellableToken, forTarget: target, withCompletion: completion, endpoint: endpoint, plugins: plugins, request: request)
        switch stubBehavior {
        case .immediate:
            stub()
        case .delayed(let delay):
            let killTimeOffset = Int64(CDouble(delay) * CDouble(NSEC_PER_SEC))
            let killTime = DispatchTime.now() + Double(killTimeOffset) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: killTime) {
                stub()
            }
        case .never:
            fatalError("Method called to stub request when stubbing is disabled.")
        }

        return cancellableToken
    }
}

/// Mark: Stubbing

public extension MoyaProvider {

    // Swift won't let us put the StubBehavior enum inside the provider class, so we'll
    // at least add some class functions to allow easy access to common stubbing closures.

    public final class func NeverStub(_: Target) -> Moya.StubBehavior {
        return .never
    }

    public final class func ImmediatelyStub(_: Target) -> Moya.StubBehavior {
        return .immediate
    }

    public final class func DelayedStub(_ seconds: TimeInterval) -> (Target) -> Moya.StubBehavior {
        return { _ in return .delayed(seconds: seconds) }
    }
}

public func convertResponseToResult(_ response: HTTPURLResponse?, request: URLRequest?, data: Data?, error: Swift.Error?) ->
    Result<Moya.Response, Moya.Error> {
    switch (response, data, error) {
    case let (.some(response), data, .none):
        let response = Moya.Response(statusCode: response.statusCode, data: data ?? Data(), request: request, response: response)
        return .success(response)
    case let (_, _, .some(error)):
        let error = Moya.Error.underlying(error)
        return .failure(error)
    default:
        let error = Moya.Error.underlying(NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: nil))
        return .failure(error)
    }
}
