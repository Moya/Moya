import Foundation
import RxSwift
#if !COCOAPODS
import Moya
#endif

/// Subclass of MoyaProvider that returns Observable instances when requests are made. Much better than using completion closures.
open class RxMoyaProvider<Target>: MoyaProvider<Target> where Target: TargetType {
    /// Initializes a reactive provider.
    public override init(endpointClosure: @escaping EndpointClosure = MoyaProvider.defaultEndpointMapping,
                         requestClosure: @escaping RequestClosure = MoyaProvider.defaultRequestMapping,
                         stubClosure: @escaping StubClosure = MoyaProvider.neverStub,
                         callbackQueue: DispatchQueue? = nil,
                         manager: Manager = RxMoyaProvider<Target>.defaultAlamofireManager(),
                         plugins: [PluginType] = [],
                         trackInflights: Bool = false) {
        super.init(endpointClosure: endpointClosure, requestClosure: requestClosure, stubClosure: stubClosure, callbackQueue: callbackQueue, manager: manager, plugins: plugins, trackInflights: trackInflights)
    }

    /// Designated request-making method.
    ///
    /// - Parameters:
    ///   - token: Entity, which provides specifications necessary for a `MoyaProvider`.
    ///   - callbackQueue: Callback queue. If nil - queue from provider initializer will be used.
    /// - Returns: Cold observable, which emits one element or error.
    open func request(_ token: Target, callbackQueue: DispatchQueue? = nil) -> Observable<Response> {
        // Creates an observable that starts a request each time it's subscribed to.
        return Observable.create { observer in
            let cancellableToken = self.request(token, callbackQueue: callbackQueue) { result in
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
    public func requestWithProgress(_ token: Target, callbackQueue: DispatchQueue? = nil) -> Observable<ProgressResponse> {
        let progressBlock: (AnyObserver) -> (ProgressResponse) -> Void = { observer in
            return { progress in
                observer.onNext(progress)
            }
        }

        let response: Observable<ProgressResponse> = Observable.create { observer in
            let cancellableToken = self.request(token, callbackQueue: callbackQueue, progress: progressBlock(observer)) { result in
                switch result {
                case .success:
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
