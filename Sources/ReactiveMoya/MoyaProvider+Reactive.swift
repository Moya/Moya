import Foundation
import ReactiveSwift
#if !COCOAPODS
import Moya
#endif

extension MoyaProvider: ReactiveExtensionsProvider {}

public extension Reactive where Base: MoyaProviderType {

    /// Designated request-making method.
    func request(_ token: Base.Target, callbackQueue: DispatchQueue? = nil) -> SignalProducer<Response, MoyaError> {
        return SignalProducer { [weak base] observer, lifetime in
            let cancellableToken = base?.request(token, callbackQueue: callbackQueue, progress: nil) { result in
                switch result {
                case let .success(response):
                    observer.send(value: response)
                    observer.sendCompleted()
                case let .failure(error):
                    observer.send(error: error)
                }
            }

            lifetime.observeEnded {
                cancellableToken?.cancel()
            }
        }
    }

    /// Designated request-making method with progress.
    func requestWithProgress(_ token: Base.Target, callbackQueue: DispatchQueue? = nil) -> SignalProducer<ProgressResponse, MoyaError> {
        let progressBlock: (Signal<ProgressResponse, MoyaError>.Observer) -> (ProgressResponse) -> Void = { observer in
            return { progress in
                observer.send(value: progress)
            }
        }

        let response: SignalProducer<ProgressResponse, MoyaError> = SignalProducer { [weak base] observer, lifetime in
            let cancellableToken = base?.request(token, callbackQueue: callbackQueue, progress: progressBlock(observer)) { result in
                switch result {
                case .success:
                    observer.sendCompleted()
                case let .failure(error):
                    observer.send(error: error)
                }
            }

            lifetime.observeEnded {
                cancellableToken?.cancel()
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
