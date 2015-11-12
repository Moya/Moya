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
        plugins: [Plugin<Target>] = [], stubScheduler: DateSchedulerType) {
            self.stubScheduler = stubScheduler
            super.init(endpointClosure: endpointClosure, requestClosure: requestClosure, stubClosure: stubClosure, manager: manager, plugins: plugins)
    }

    override public init(endpointClosure: EndpointClosure = MoyaProvider.DefaultEndpointMapping,
        requestClosure: RequestClosure = MoyaProvider.DefaultRequestMapping,
        stubClosure: StubClosure = MoyaProvider.NeverStub,
        manager: Manager = Alamofire.Manager.sharedInstance,
        plugins: [Plugin<Target>] = []) {
            self.stubScheduler = nil
            super.init(endpointClosure: endpointClosure, requestClosure: requestClosure, stubClosure: stubClosure, manager: manager, plugins: plugins)
    }
    
    /// Designated request-making method.
    public func request(token: Target) -> SignalProducer<MoyaResponse, NSError> {
        
        // Creates a producer that starts a request each time it's started.
        return SignalProducer { [weak self] observer, requestDisposable in
            let cancellableToken = self?.request(token) { data, statusCode, response, error in
                if let error = error {
                    observer.sendFailed(error as NSError)
                } else {
                    if let data = data, let statusCode = statusCode {
                        observer.sendNext(MoyaResponse(statusCode: statusCode, data: data, response: response))
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
        var canceled = false
        let stub = createStubFunction(&canceled, forTarget: target, withCompletion: completion, endpoint: endpoint, plugins: plugins)
        switch stubBehavior {
        case .Immediate:
            stubScheduler.schedule(stub)
        case .Delayed(let seconds):
            let date = NSDate(timeIntervalSinceNow: seconds)
            stubScheduler.scheduleAfter(date, action: stub)
        case .Never:
            fatalError("Attempted to stub request when behavior requested was never stub!")
        }
        // Todo: refactor cancellation behavior out of `createStubFunction` so that we can use disposables.
        return CancellableToken {
            canceled = true
        }
    }

    public func request(token: Target) -> RACSignal {
        return toRACSignal(request(token))
    }
}
