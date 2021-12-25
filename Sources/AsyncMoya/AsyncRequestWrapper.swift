import Foundation
import Moya

#if swift(>=5.5)

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
internal class AsyncMoyaRequestWrapper {
    
    var performRequest: (CheckedContinuation<Result<Response, MoyaError>, Never>) -> Moya.Cancellable?
    var cancellable: Moya.Cancellable?
    
    init(_ performRequest: @escaping (CheckedContinuation<Result<Response, MoyaError>, Never>) -> Moya.Cancellable?) {
        self.performRequest = performRequest
    }
    
    func perform(continuation: CheckedContinuation<Result<Response, MoyaError>, Never>) {
        cancellable = performRequest(continuation)
    }
    
    func cancel() {
        cancellable?.cancel()
    }
    
}

#endif
