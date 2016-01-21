import Foundation

/// Request provider class. Requests should be made through this class only.
public class MoyaProvider<Target: TargetType> {

    /// Closure that defines the endpoints for the provider.
    public typealias EndpointClosure = Target -> Endpoint

    /// Closure that resolves an Endpoint into an NSURLRequest.
    public typealias RequestClosure = (Endpoint, NSURLRequest -> Void) -> Void

    public let endpointClosure: EndpointClosure
    public let requestClosure: RequestClosure

    /// A list of plugins
    /// e.g. for logging, network activity indicator or credentials
    public let plugins: [PluginType]

    public let backend: MoyaProviderBackendType

    /// TODO: Just keeping test cases
    public var manager: Manager { return self.backend.manager }

    /// Initializes a provider.
    public init(endpointClosure: EndpointClosure = DefaultEndpointMapping,
                requestClosure: RequestClosure = DefaultRequestMapping,
                stubBehavior: StubBehavior = .Never,
                manager: Manager = DefaultAlamofireManager(),
                plugins: [PluginType] = []) {

        self.endpointClosure = endpointClosure
        self.requestClosure = requestClosure
        self.plugins = plugins
        
        switch stubBehavior {
        case .Never:
            self.backend = MoyaProviderBackend(manager: manager)
        default:
            self.backend = MoyaProviderStubBackend(manager: manager, stubBehavior: stubBehavior)
        }
    }

    public init(backend: MoyaProviderBackendType,
                endpointClosure: EndpointClosure = DefaultEndpointMapping,
                requestClosure: RequestClosure = DefaultRequestMapping,
                plugins: [PluginType] = []) {
        self.backend = backend
        self.endpointClosure = endpointClosure
        self.requestClosure = requestClosure
        self.plugins = plugins
    }

    /// Designated request-making method. Returns a Cancellable token to cancel the request later.
    public func request(target: Target, completion: Moya.Completion) -> Cancellable {
        let endpoint = self.endpointClosure(target)
        var cancellableToken = CancellableWrapper()

        let performNetworking = { (request: NSURLRequest) in
            if cancellableToken.isCancelled { return }

            cancellableToken.innerCancellable = self.backend.request(target, endpoint: endpoint, request: request, plugins: self.plugins, completion: completion)
        }

        requestClosure(endpoint, performNetworking)

        return cancellableToken
    }
}

public class MoyaCommonProvider {
    /// Closure that defines the endpoints for the provider.
    public typealias EndpointClosure = TargetType -> Endpoint

    /// Closure that resolves an Endpoint into an NSURLRequest.
    public typealias RequestClosure = (Endpoint, NSURLRequest -> Void) -> Void

    public let endpointClosure: EndpointClosure
    public let requestClosure: RequestClosure

    /// A list of plugins
    /// e.g. for logging, network activity indicator or credentials
    public let plugins: [PluginType]

    public let backend: MoyaProviderBackendType

    /// TODO: Just keeping test cases no need to change
    public var manager: Manager { return self.backend.manager }

    /// Initializes a provider.
    public init(backend: MoyaProviderBackendType,
                endpointClosure: EndpointClosure = DefaultCommonEndpointMapping,
                requestClosure: RequestClosure = DefaultRequestMapping,
                plugins: [PluginType] = []) {
        self.backend = backend
        self.endpointClosure = endpointClosure
        self.requestClosure = requestClosure
        self.plugins = plugins
    }

    /// Designated request-making method. Returns a Cancellable token to cancel the request later.
    public func request(target: TargetType, completion: Moya.Completion) -> Cancellable {
        let endpoint = self.endpointClosure(target)
        var cancellableToken = CancellableWrapper()

        let performNetworking = { (request: NSURLRequest) in
            if cancellableToken.isCancelled { return }

            cancellableToken.innerCancellable = self.backend.request(target, endpoint: endpoint, request: request, plugins: self.plugins, completion: completion)
        }

        requestClosure(endpoint, performNetworking)

        return cancellableToken
    }
}

private struct CancellableWrapper: Cancellable {
    var innerCancellable: CancellableToken? = nil

    private var isCancelled = false

    func cancel() {
        innerCancellable?.cancel()
    }
}
