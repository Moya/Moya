import Foundation
import Moya

#if swift(>=5.5)

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension MoyaProvider {
    /// Async request
    /// - Parameter target: Entity, with provides Moya.Target protocol
    /// - Returns: Result type with response and error
    func asyncRequest(_ target: Target) async -> Result<Response, MoyaError> {
        return await withCheckedContinuation { moyaContinuation in
            self.request(target) { result in
                switch result {
                case .success(let response):
                    moyaContinuation.resume(returning: .success(response))
                case .failure(let moyaError):
                    moyaContinuation.resume(returning: .failure(moyaError))
                }
            }
        }
    }
    
    /// Async request with progress using `AsyncStream`
    /// - Parameter target: Entity, with provides Moya.Target protocol
    /// - Returns: `AsyncStream<Result<ProgressResponse, MoyaError>>`  with Result type of progress and error
    func requestWithProgress(_ target: Target) async -> AsyncStream<Result<ProgressResponse, MoyaError>> {
        return AsyncStream { stream in
            let cancelable = self.request(target) { progress in
                stream.yield(.success(progress))
            } completion: { result in
                switch result {
                case .success:
                    stream.finish()
                case .failure(let error):
                    stream.yield(.failure(error))
                    stream.finish()
                }
            }
            stream.onTermination = { @Sendable _ in
                cancelable.cancel()
            }
        }
    }
}

#endif
