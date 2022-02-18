import Foundation
import Moya

#if swift(>=5.5)

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
internal class AsyncMoyaRequestWrapper {

    internal typealias MoyaContinuation = CheckedContinuation<Result<Response, MoyaError>, Never>

    var performRequest: (MoyaContinuation) -> Moya.Cancellable?
    var cancellable: Moya.Cancellable?

    init(_ performRequest: @escaping (MoyaContinuation) -> Moya.Cancellable?) {
        self.performRequest = performRequest
    }

    func perform(continuation: MoyaContinuation) {
        cancellable = performRequest(continuation)
    }

    func cancel() {
        cancellable?.cancel()
    }
}

#endif
