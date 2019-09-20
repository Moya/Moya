import Foundation

final class MoyaRequestInterceptor: RequestInterceptor {

    var prepare: ((URLRequest) -> URLRequest)?
    var willSend: ((URLRequest) -> Void)?
    var retry: ((Request, Session, Error, @escaping ((RetryResult) -> Void)) -> Void)?

    init(prepare: ((URLRequest) -> URLRequest)? = nil, willSend: ((URLRequest) -> Void)? = nil, retry: ((Request, Session, Error, @escaping ((RetryResult) -> Void)) -> Void)? = nil) {
        self.prepare = prepare
        self.willSend = willSend
        self.retry = retry
    }

    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        let request = prepare?(urlRequest) ?? urlRequest
        willSend?(request)
        completion(.success(request))
    }

    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        retry?(request, session, error, completion)
    }
}
