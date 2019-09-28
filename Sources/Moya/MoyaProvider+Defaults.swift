import Foundation

/// These functions are default mappings to `MoyaProvider`'s properties: endpoints, requests, session etc.
public extension MoyaProvider {

    final class func defaultEndpointMapping(for target: Target) -> Endpoint {
        return Endpoint(
            url: URL(target: target).absoluteString,
            sampleResponseClosure: { .networkResponse(200, target.sampleData) },
            method: target.method,
            task: target.task,
            httpHeaderFields: target.headers
        )
    }

    final class func defaultRequestMapping(for endpoint: Endpoint, closure: RequestResultClosure) {
        do {
            let urlRequest = try endpoint.urlRequest()
            closure(.success(urlRequest))
        } catch MoyaError.requestMapping(let url) {
            closure(.failure(MoyaError.requestMapping(url)))
        } catch MoyaError.parameterEncoding(let error) {
            closure(.failure(MoyaError.parameterEncoding(error)))
        } catch {
            closure(.failure(MoyaError.underlying(error, nil)))
        }
    }

    final class func defaultAlamofireSession() -> Session {
        let configuration = URLSessionConfiguration.default
        configuration.headers = .default

        return Session(configuration: configuration, startRequestsImmediately: false)
    }
}

public extension MoyaProvider {

    /// Do not stub.
    final class func neverStub(_: Target) -> Moya.StubBehavior {
        return .never
    }

    /// Return a response immediately.
    final class func immediatelyStub(_: Target) -> Moya.StubBehavior {
        return .immediate
    }

    /// Return a response after a delay.
    final class func delayedStub(_ seconds: TimeInterval) -> (Target) -> Moya.StubBehavior {
        return { _ in return .delayed(seconds: seconds) }
    }
}

public extension MoyaProvider {

    /// Do not retry, ever.
    final class func doNotRetry(_: RequestType, _: Target, _: Error?, _ completion: @escaping RetryResultClosure) {
        completion(.doNotRetry)
    }
}
