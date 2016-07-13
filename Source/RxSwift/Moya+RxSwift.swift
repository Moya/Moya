import Foundation
import RxSwift

/// Subclass of MoyaProvider that returns Observable instances when requests are made. Much better than using completion closures.
public class RxMoyaProvider<Target where Target: TargetType>: MoyaProvider<Target> {
    /// Initializes a reactive provider.
    override public init(endpointClosure: EndpointClosure = MoyaProvider.DefaultEndpointMapping,
        requestClosure: RequestClosure = MoyaProvider.DefaultRequestMapping,
        stubClosure: StubClosure = MoyaProvider.NeverStub,
        manager: Manager = RxMoyaProvider<Target>.DefaultAlamofireManager(),
        plugins: [PluginType] = [],
        trackInflights: Bool = false) {
            super.init(endpointClosure: endpointClosure, requestClosure: requestClosure, stubClosure: stubClosure, manager: manager, plugins: plugins, trackInflights: trackInflights)
    }

    /// Designated request-making method.
    public func request(token: Target) -> Observable<Response> {

        // Creates an observable that starts a request each time it's subscribed to.
        return Observable.create { [weak self] observer in
            let cancellableToken = self?.request(token) { result in
                switch result {
                case let .Success(response):
                    observer.onNext(response)
                    observer.onCompleted()
                    break
                case let .Failure(error):
                    observer.onError(error)
                }
            }

            return AnonymousDisposable {
                cancellableToken?.cancel()
            }
        }
    }
}

public extension RxMoyaProvider {
    public func requestWithProgress(token: Target) -> Observable<ProgressResponse> {
        let progressBlock = { (observer: AnyObserver) -> (ProgressResponse) -> Void in
            return { (progress: ProgressResponse) in
                observer.onNext(progress)
            }
        }

        let response: Observable<ProgressResponse> = Observable.create { [weak self] observer in
            let cancellableToken = self?.request(token, queue: nil, progress: progressBlock(observer)) { result in
                switch result {
                case let .Success(response):
                    observer.onNext(ProgressResponse(response: response))
                    observer.onCompleted()
                    break
                case let .Failure(error):
                    observer.onError(error)
                }
            }

            return AnonymousDisposable {
                cancellableToken?.cancel()
            }
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
