import Foundation
import ReactiveCocoa

/// Subclass of MoyaProvider that returns SignalProducer instances when requests are made. Much better than using completion closures.
public class ReactiveCocoaMoyaProvider<Target where Target: TargetType>: MoyaProvider<Target> {
    private let stubScheduler: DateSchedulerType?
    /// Initializes a reactive provider.
    public init(endpointClosure: EndpointClosure = MoyaProvider.DefaultEndpointMapping,
        requestClosure: RequestClosure = MoyaProvider.DefaultRequestMapping,
        stubClosure: StubClosure = MoyaProvider.NeverStub,
        manager: Manager = ReactiveCocoaMoyaProvider<Target>.DefaultAlamofireManager(),
        plugins: [PluginType] = [], stubScheduler: DateSchedulerType? = nil) {
            self.stubScheduler = stubScheduler
            super.init(endpointClosure: endpointClosure, requestClosure: requestClosure, stubClosure: stubClosure, manager: manager, plugins: plugins)
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

    override func stubRequest(target: Target, request: NSURLRequest, completion: Moya.Completion, endpoint: Endpoint<Target>, stubBehavior: Moya.StubBehavior) -> CancellableToken {
        guard let stubScheduler = self.stubScheduler else {
            return super.stubRequest(target, request: request, completion: completion, endpoint: endpoint, stubBehavior: stubBehavior)
        }
        notifyPluginsOfImpendingStub(request, target: target)
        var dis: Disposable? = .None
        let token = CancellableToken {
            dis?.dispose()
        }
        let stub = createStubFunction(token, forTarget: target, withCompletion: completion, endpoint: endpoint, plugins: plugins)

        switch stubBehavior {
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

    @available(*, deprecated, message="This will be removed when ReactiveCocoa 4 becomes final. Please visit https://github.com/Moya/Moya/issues/298 for more information.")
    public func request(token: Target) -> RACSignal {
        return request(token).toRACSignal()
    }
}
