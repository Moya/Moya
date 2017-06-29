import Foundation
import ReactiveSwift
#if !COCOAPODS
import Moya
#endif

extension MoyaProvider: ReactiveExtensionsProvider {}

public extension Reactive where Base: MoyaProviderProtocol {
    
    /// Designated request-making method.
    public func request(_ token: Base.Target) -> SignalProducer<Response, MoyaError> {
        // Creates a producer that starts a request each time it's started.
        return SignalProducer { [weak provider = self.base] observer, requestDisposable in
            let cancellableToken = provider?.request(token) { result in
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
    
    public func requestWithProgress(token: Base.Target) -> SignalProducer<ProgressResponse, MoyaError> {
        let progressBlock: (Signal<ProgressResponse, MoyaError>.Observer) -> (ProgressResponse) -> Void = { observer in
            return { progress in
                observer.send(value: progress)
            }
        }
        
        let response: SignalProducer<ProgressResponse, MoyaError> = SignalProducer { [weak provider = self.base] observer, disposable in
            let cancellableToken = provider?.request(token, queue: nil, progress: progressBlock(observer)) { result in
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

/// Subclass of MoyaProvider that returns SignalProducer instances when requests are made. Much better than using completion closures.
open class ReactiveSwiftMoyaProvider<Target>: MoyaProvider<Target> where Target: TargetType {

    /// Designated request-making method.
    open func request(_ token: Target) -> SignalProducer<Response, MoyaError> {

        // Creates a producer that starts a request each time it's started.
        return self.reactive.request(token)
    }
    
    open func requestWithProgress(token: Target) -> SignalProducer<ProgressResponse, MoyaError> {
        return reactive.requestWithProgress(token: token)
    }
}
