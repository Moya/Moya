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
        plugins: [PluginType] = [], stubScheduler: DateSchedulerType? = nil,
        trackInflights: Bool = false) {
            self.stubScheduler = stubScheduler
            super.init(endpointClosure: endpointClosure, requestClosure: requestClosure, stubClosure: stubClosure, manager: manager, plugins: plugins, trackInflights: trackInflights)
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
}

public extension ReactiveCocoaMoyaProvider {
    public func requestWithProgress(token: Target) -> SignalProducer<ProgressResponse, Error> {
        let progressBlock = { (observer: Signal<ProgressResponse, Error>.Observer) -> (ProgressResponse) -> Void in
            return { (progress: ProgressResponse) in
                observer.sendNext(progress)
            }
        }
        
        let response: SignalProducer<ProgressResponse, Error> = SignalProducer { [weak self] observer, disposable in
            let cancellableToken = self?.request(token, queue: nil, progress: progressBlock(observer)) { result in
                switch result {
                case let .Success(response):
                    observer.sendNext(ProgressResponse(response: response))
                    observer.sendCompleted()
                case let .Failure(error):
                    observer.sendFailed(error)
                }
            }
            
            let cleanUp = ActionDisposable {
                cancellableToken?.cancel()
            }
            disposable.addDisposable(cleanUp)
        }
        
        // Accumulate all progress and combine them when the result comes
        return response.scan(ProgressResponse()) { (last, progress) in
            let totalBytes = progress.totalBytes > 0 ? progress.totalBytes : last.totalBytes
            let bytesExpected = progress.bytesExpected > 0 ? progress.bytesExpected : last.bytesExpected
            let response = progress.response ?? last.response
            return ProgressResponse(totalBytes: totalBytes, bytesExpected: bytesExpected, response: response)
        }
    }
}
