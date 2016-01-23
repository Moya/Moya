import Foundation
import ReactiveCocoa

public class ReactiveCocoaMoyaProviderStubBackend: MoyaProviderStubBackend {
    private let stubScheduler: DateSchedulerType?

    public init(stubBehavior: StubBehavior = .Immediate,
                stubScheduler: DateSchedulerType? = nil,
                manager: Manager = DefaultAlamofireManager()) {
        self.stubScheduler = stubScheduler
        super.init(manager: manager, stubBehavior: stubBehavior)
    }

    public override func request(target: TargetType, endpoint: Endpoint, request: NSURLRequest, plugins: [PluginType], completion: Moya.Completion) -> CancellableToken {
        guard let stubScheduler = self.stubScheduler else {
            return super.request(target, endpoint: endpoint, request: request, plugins: plugins, completion: completion)
        }
        notifyPluginsOfImpendingStub(request, target: target, plugins: plugins)
        var dis: Disposable? = .None
        let token = CancellableToken {
            dis?.dispose()
        }
        let stub = createStubFunction(token, forTarget: target, endpoint: endpoint, plugins: plugins, withCompletion: completion)

        switch self.stubBehavior {
        case .Immediate:
            dis = stubScheduler.schedule(stub)
        case .Delayed(let seconds):
            let date = NSDate(timeIntervalSinceNow: seconds)
            dis = stubScheduler.scheduleAfter(date, action: stub)
        case .Never:
            fatalError("Attempted to stub request when behavior requested was never stub!")
        }
        return token
    }
}

/// Subclass of MoyaProvider that returns SignalProducer instances when requests are made. Much better than using completion closures.
public class ReactiveCocoaMoyaProvider<Target where Target: TargetType>: MoyaProvider<Target> {
    /// Initializes a reactive provider.
    public init(endpointClosure: EndpointClosure = DefaultEndpointMapping,
                requestClosure: RequestClosure = DefaultRequestMapping,
                stubBehavior: StubBehavior = .Never,
                manager: Manager = Manager.sharedInstance,
                plugins: [PluginType] = [], stubScheduler: DateSchedulerType? = nil) {
        switch stubBehavior {
        case .Never:
            super.init(backend: MoyaProviderBackend(manager: manager),
                       endpointClosure: endpointClosure, requestClosure: requestClosure, plugins: plugins)
        default:
            super.init(backend: ReactiveCocoaMoyaProviderStubBackend(stubBehavior: stubBehavior, stubScheduler: stubScheduler, manager: manager),
                       endpointClosure: endpointClosure, requestClosure: requestClosure, plugins: plugins)
        }
    }
    
    /// Designated request-making method.
    public func request(token: Target) -> SignalProducer<Response, Error> {
        
        // Creates a producer that starts a request each time it's started.
        return SignalProducer { [weak self] observer, requestDisposable in
            let cancellableToken = self?.request(token) { result in
                switch result {
                case let .Success(response):
                    observer.sendNext(response)
                    observer.sendCompleted()
                    break
                case let .Failure(error):
                    observer.sendFailed(error)
                }
            }
            
            requestDisposable.addDisposable {
                // Cancel the request
                cancellableToken?.cancel()
            }
        }
    }

    @available(*, deprecated, message="This will be removed when ReactiveCocoa 4 becomes final. Please visit https://github.com/Moya/Moya/issues/298 for more information.")
    public func request(token: Target) -> RACSignal {
        return request(token).toRACSignal()
    }
}
