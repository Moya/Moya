import Foundation
import Moya

#if swift(>=5.5)

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension MoyaProvider {

    /// Designated request-making method.
    ///
    /// - Parameters:
    ///   - target: Entity, which provides specifications necessary for a `MoyaProvider`.
    /// - Returns: `Result<Response, MoyaError>`
    func request(_ target: Target) async -> Result<Response, MoyaError> {
        let asyncRequestWrapper = AsyncMoyaRequestWrapper { [weak self] continuation in
            guard let self = self else { return nil }
            return self.request(target) { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: .success(response))
                case .failure(let moyaError):
                    continuation.resume(returning: .failure(moyaError))
                }
            }
        }

        return await withTaskCancellationHandler(handler: {
            asyncRequestWrapper.cancel()
        }, operation: {
            await withCheckedContinuation({ continuation in
                asyncRequestWrapper.perform(continuation: continuation)
            })
        })
    }

    /// Designated request-making method with progress.
    func requestWithProgress(_ target: Target) async -> AsyncStream<Result<ProgressResponse, MoyaError>> {
        AsyncStream { stream in
            let cancellable = self.request(target, progress: { progress in
                stream.yield(.success(progress))
            }, completion: { result in
                switch result {
                case .success:
                    stream.finish()
                case .failure(let error):
                    stream.yield(.failure(error))
                    stream.finish()
                }
            })
            stream.onTermination = { @Sendable _ in
                cancellable.cancel()
            }
        }
    }
}

#endif
