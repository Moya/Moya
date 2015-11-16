import Foundation
import ReactiveCocoa
import Alamofire

/// Subclass of MoyaProvider that returns SignalProducer instances when requests are made. Much better than using completion closures.
public class ReactiveCocoaMoyaProvider<Target where Target: MoyaTarget>: MoyaProvider<Target> {
    private let stubScheduler: DateSchedulerType?
    /// Initializes a reactive provider.
    public init(endpointClosure: EndpointClosure = MoyaProvider.DefaultEndpointMapping,
        requestClosure: RequestClosure = MoyaProvider.DefaultRequestMapping,
        stubClosure: StubClosure = MoyaProvider.NeverStub,
        manager: Manager = Alamofire.Manager.sharedInstance,
        plugins: [Plugin<Target>] = [], stubScheduler: DateSchedulerType? = nil) {
            self.stubScheduler = stubScheduler
            super.init(endpointClosure: endpointClosure, requestClosure: requestClosure, stubClosure: stubClosure, manager: manager, plugins: plugins)
    }
    
    /// Designated request-making method.
    public func request(token: Target) -> SignalProducer<Response, MoyaError> {
        
        // Creates a producer that starts a request each time it's started.
        return SignalProducer { [weak self] observer, requestDisposable in
            let cancellableToken = self?.request(token) { data, statusCode, response, error in
                if let error = error {
                    observer.sendFailed(.Underlying(error))
                } else {
                    if let data = data, let statusCode = statusCode {
                        observer.sendNext(Response(statusCode: statusCode, data: data, response: response))
                    }
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

    @available(*, deprecated, message="This will be removed when ReactiveCocoa 4 becomes final. Please visit https://github.com/Moya/Moya/issues/298 for more information.")
    public func request(token: Target) -> RACSignal {
        return toRACSignal(request(token))
    }
}
