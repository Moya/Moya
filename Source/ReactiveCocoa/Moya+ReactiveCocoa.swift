import Foundation
import ReactiveCocoa
import Alamofire

/// Subclass of NetworkResourceProvider that returns SignalProducer instances when requests are made. Much better than using completion closures.
public class ReactiveCocoaNetworkResourceProvider<Target where Target: TargetType>: NetworkResourceProvider<Target> {
    private let stubScheduler: DateSchedulerType?
    /// Initializes a reactive provider.
    public init(endpointClosure: EndpointClosure = NetworkResourceProvider.DefaultEndpointMapping,
        requestClosure: RequestClosure = NetworkResourceProvider.DefaultRequestMapping,
        stubClosure: StubClosure = NetworkResourceProvider.NeverStub,
        manager: Manager = Alamofire.Manager.sharedInstance,
        plugins: [Plugin] = [], stubScheduler: DateSchedulerType? = nil) {
            self.stubScheduler = stubScheduler
            super.init(endpointClosure: endpointClosure, requestClosure: requestClosure, stubClosure: stubClosure, manager: manager, plugins: plugins)
    }
    
    /// Designated request-making method.
    public func request(token: Target) -> SignalProducer<Response, MoyaError> {
        
        // Creates a producer that starts a request each time it's started.
        return SignalProducer { [weak self] observer, requestDisposable in
            let cancellableToken = self?.request(token) { response, error in
                if let error = error {
                    observer.sendFailed(.Underlying(error))
                } else if let response = response {
                    observer.sendNext(response)
                    observer.sendCompleted()
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

    public func request(token: Target) -> RACSignal {
        return toRACSignal(request(token))
    }
}
