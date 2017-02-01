import Foundation
import RxSwift
#if !COCOAPODS
import Moya
#endif

/// Subclass of MoyaProvider that returns Observable instances when requests are made. Much better than using completion closures.
open class RxMoyaProvider<Target>: MoyaProvider<Target> where Target: TargetType {
    /// Initializes a reactive provider.
    override public init(endpointClosure: @escaping EndpointClosure = MoyaProvider.defaultEndpointMapping,
                         requestClosure: @escaping RequestClosure = MoyaProvider.defaultRequestMapping,
                         stubClosure: @escaping StubClosure = MoyaProvider.neverStub,
                         manager: Manager = RxMoyaProvider<Target>.defaultAlamofireManager(),
                         plugins: [PluginType] = [],
                         trackInflights: Bool = false) {
        super.init(endpointClosure: endpointClosure, requestClosure: requestClosure, stubClosure: stubClosure, manager: manager, plugins: plugins, trackInflights: trackInflights)
    }

    /// Designated request-making method.
    open func request(_ token: Target) -> Observable<Response> {

        // Creates an observable that starts a request each time it's subscribed to.
        return Observable.create { observer in
            let cancellableToken = self.request(token) { result in
                switch result {
                case let .success(response):
                    observer.onNext(response)
                    observer.onCompleted()
                case let .failure(error):
                    observer.onError(error)
                }
            }

            return Disposables.create {
                cancellableToken.cancel()
            }
        }
    }
}

public extension RxMoyaProvider {
    public func requestWithProgress(_ token: Target) -> Observable<ProgressResponse> {
        let progressBlock: (AnyObserver) -> (ProgressResponse) -> Void = { observer in
            return { progress in
                observer.onNext(progress)
            }
        }

        let response: Observable<ProgressResponse> = Observable.create { observer in
            let cancellableToken = self.request(token, queue: nil, progress: progressBlock(observer)) { result in
                switch result {
                case let .success(response):
                    observer.onNext(ProgressResponse(response: response))
                    observer.onCompleted()
                case let .failure(error):
                    observer.onError(error)
                }
            }

            return Disposables.create {
                cancellableToken.cancel()
            }
        }

        // Accumulate all progress and combine them when the result comes
        return response.scan(ProgressResponse()) { last, progress in
            let progressObject = progress.progressObject ?? last.progressObject
            let response = progress.response ?? last.response
            return ProgressResponse(progress: progressObject, response: response)
        }
    }
}
