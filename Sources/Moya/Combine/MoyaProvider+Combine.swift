#if canImport(Combine)

import Foundation
import Combine

#if !COCOAPODS
import Moya
#endif

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publishable where Base: MoyaProviderType {

    /// Designated request-making method.
    ///
    /// - Parameters:
    ///   - target: Entity, which provides specifications necessary for a `MoyaProvider`.
    ///   - callbackQueue: Callback queue. If nil - queue from provider initializer will be used.
    /// - Returns: `AnyPublisher<Response, MoyaError`
    func request(_ target: Base.Target, callbackQueue: DispatchQueue? = nil) -> AnyPublisher<Response, MoyaError> {
        return MoyaPublisher { [weak base] subscriber in
                return base?.request(target, callbackQueue: callbackQueue, progress: nil) { result in
                    switch result {
                    case let .success(response):
                        subscriber.receive(response)
                    case let .failure(error):
                        subscriber.receive(completion: .failure(error))
                    }
                }
            }
            .eraseToAnyPublisher()
    }
}

#endif
