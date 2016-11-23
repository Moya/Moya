import Foundation
import ReactiveSwift
#if !COCOAPODS
import Moya
#endif

/// Subclass of MoyaProvider that returns SignalProducer instances when requests are made. Much better than using completion closures.
open class ReactiveCocoaMoyaProvider<Target>: MoyaProvider<Target> where Target: TargetType {
    private let stubScheduler: DateSchedulerProtocol?
    /// Initializes a reactive provider.
    public init(endpointClosure: @escaping EndpointClosure = MoyaProvider.defaultEndpointMapping,
        requestClosure: @escaping RequestClosure = MoyaProvider.defaultRequestMapping,
        stubClosure: @escaping StubClosure = MoyaProvider.neverStub,
        manager: Manager = ReactiveCocoaMoyaProvider<Target>.defaultAlamofireManager(),
        plugins: [PluginType] = [], stubScheduler: DateSchedulerProtocol? = nil,
        trackInflights: Bool = false) {
            self.stubScheduler = stubScheduler
            super.init(endpointClosure: endpointClosure, requestClosure: requestClosure, stubClosure: stubClosure, manager: manager, plugins: plugins, trackInflights: trackInflights)
    }

    /// Designated request-making method.
    open func request(token: Target) -> SignalProducer<Response, Moya.Error> {

        // Creates a producer that starts a request each time it's started.
        return SignalProducer { [weak self] observer, requestDisposable in
            let cancellableToken = self?.request(token) { result in
                switch result {
                case let .success(response):
                    observer.send(value: response)
                    observer.sendCompleted()
                case let .failure(error):
                    observer.send(error: error)
                }
            }

            requestDisposable.add {
                // Cancel the request
                cancellableToken?.cancel()
            }
        }
    }

    open override func stubRequest(_ target: Target, request: URLRequest, completion: @escaping Moya.Completion, endpoint: Endpoint<Target>, stubBehavior: Moya.StubBehavior) -> CancellableToken {
        guard let stubScheduler = self.stubScheduler else {
            return super.stubRequest(target, request: request, completion: completion, endpoint: endpoint, stubBehavior: stubBehavior)
        }
        notifyPluginsOfImpendingStub(request, target: target)
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

public extension ReactiveCocoaMoyaProvider {
    public func requestWithProgress(token: Target) -> SignalProducer<ProgressResponse, Moya.Error> {
        let progressBlock = { (observer: Signal<ProgressResponse, Moya.Error>.Observer) -> (ProgressResponse) -> Void in
            return { progress in
                observer.send(value: progress)
            }
        }

        let response: SignalProducer<ProgressResponse, Moya.Error> = SignalProducer { [weak self] observer, disposable in
            let cancellableToken = self?.request(token, queue: nil, progress: progressBlock(observer)) { result in
                switch result {
                case let .success(response):
                    observer.send(value: ProgressResponse(response: response))
                    observer.sendCompleted()
                case let .failure(error):
                    observer.send(error: error)
                }
            }

            let cleanUp = ActionDisposable {
                cancellableToken?.cancel()
            }
            disposable.add(cleanUp)
        }

        // Accumulate all progress and combine them when the result comes
        return response.scan(ProgressResponse()) { last, progress in
            let progressObject = progress.progressObject ?? last.progressObject
            let response = progress.response ?? last.response
            return ProgressResponse(progress: progressObject, response: response)
        }
    }
}
