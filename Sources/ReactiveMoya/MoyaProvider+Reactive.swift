import Foundation
import ReactiveSwift
#if !COCOAPODS
import Moya
#endif

extension MoyaProvider: ReactiveExtensionsProvider {}

public extension Reactive where Base: MoyaProviderProtocol {

    /// Designated request-making method.
    public func request(_ token: Base.Target) -> SignalProducer<Response, MoyaError> {
        return base.reactiveRequest(token)
    }

    /// Designated request-making method with progress.
    public func requestWithProgress(_ token: Base.Target) -> SignalProducer<ProgressResponse, MoyaError> {
        return base.reactiveRequestWithProgress(token)
    }
}

internal extension MoyaProviderProtocol {

    internal func reactiveRequest(_ token: Target) -> SignalProducer<Response, MoyaError> {
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
                cancellableToken?.cancel()
            }
        }
    }

    internal func reactiveRequestWithProgress(_ token: Target) -> SignalProducer<ProgressResponse, MoyaError> {
        let progressBlock: (Signal<ProgressResponse, MoyaError>.Observer) -> (ProgressResponse) -> Void = { observer in
            return { progress in
                observer.send(value: progress)
            }
        }

        let response: SignalProducer<ProgressResponse, MoyaError> = SignalProducer { [weak self] observer, disposable in
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
