#if !COCOAPODS
    import Moya
#endif
import ReactiveSwift

@available(*, unavailable, renamed: "ReactiveSwiftMoyaProvider", message: "ReactiveCocoaMoyaProvider has been renamed to ReactiveSwiftMoyaProvider in version 8.0.0")
public class ReactiveCocoaMoyaProvider { }

extension ReactiveSwiftMoyaProvider {
    @available(*, unavailable, renamed: "request(_:)")
    public func request(token: Target) -> SignalProducer<Response, MoyaError> { fatalError() }
}

/// Subclass of MoyaProvider that returns SignalProducer instances when requests are made. Much better than using completion closures.
@available(*, deprecated: 9.0.0, message: "Please use MoyaProvider with reactive property: provider.reactive.request(_:).")
open class ReactiveSwiftMoyaProvider<Target>: MoyaProvider<Target> where Target: TargetType {
    private let stubScheduler: DateScheduler?
    /// Initializes a reactive provider.
    public init(endpointClosure: @escaping EndpointClosure = MoyaProvider.defaultEndpointMapping,
                requestClosure: @escaping RequestClosure = MoyaProvider.defaultRequestMapping,
                stubClosure: @escaping StubClosure = MoyaProvider.neverStub,
                manager: Manager = ReactiveSwiftMoyaProvider<Target>.defaultAlamofireManager(),
                plugins: [PluginType] = [],
                stubScheduler: DateScheduler? = nil,
                trackInflights: Bool = false) {
        self.stubScheduler = stubScheduler
        super.init(endpointClosure: endpointClosure, requestClosure: requestClosure, stubClosure: stubClosure, manager: manager, plugins: plugins, trackInflights: trackInflights)
    }
    
    /// Designated request-making method.
    open func request(_ token: Target) -> SignalProducer<Response, MoyaError> {
        // Creates a producer that starts a request each time it's started.
        return self._request(token)
    }
    
    open func requestWithProgress(token: Target) -> SignalProducer<ProgressResponse, MoyaError> {
        return self._requestWithProgress(token: token)
    }
    
    open override func stubRequest(_ target: Target, request: URLRequest, completion: @escaping Moya.Completion, endpoint: Endpoint<Target>, stubBehavior: Moya.StubBehavior) -> CancellableToken {
        guard let stubScheduler = self.stubScheduler else {
            return super.stubRequest(target, request: request, completion: completion, endpoint: endpoint, stubBehavior: stubBehavior)
        }
        notifyPluginsOfImpendingStub(for: request, target: target)
        var dis: Disposable? = .none
        let token = CancellableToken {
            dis?.dispose()
        }
        let stub = createStubFunction(token, forTarget: target, withCompletion: completion, endpoint: endpoint, plugins: plugins, request: request)
        
        switch stubBehavior {
        case .immediate:
            dis = stubScheduler.schedule(stub)
        case .delayed(let seconds):
            let date = Date(timeIntervalSinceNow: seconds)
            dis = stubScheduler.schedule(after: date, action: stub)
        case .never:
            fatalError("Attempted to stub request when behavior requested was never stubbed!")
        }
        return token
    }
}
