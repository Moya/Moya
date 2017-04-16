import Foundation
import Alamofire

/// These functions are default mappings to `MoyaProvider`'s properties: endpoints, requests, manager, etc.
public extension MoyaProvider {
    public final class func defaultEndpointMapping(for target: Target) -> Endpoint<Target> {
        return Endpoint(
            url: url(for: target).absoluteString,
            sampleResponseClosure: { .networkResponse(200, target.sampleData) },
            method: target.method,
            parameters: target.parameters,
            parameterEncoding: target.parameterEncoding
        )
    }

    public final class func defaultRequestMapping(for endpoint: Endpoint<Target>, closure: RequestResultClosure) {
        if let urlRequest = endpoint.urlRequest {
            closure(.success(urlRequest))
        } else {
            closure(.failure(MoyaError.requestMapping(endpoint.url)))
        }
    }

    public final class func defaultAlamofireManager() -> Manager {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = Manager.defaultHTTPHeaders

        let manager = Manager(configuration: configuration)
        manager.startRequestsImmediately = false
        return manager
    }

    // When a TargetType's path is empty, URL.appendingPathComponent may introduce trailing /, which may not be wanted in some cases
    // See: https://github.com/Moya/Moya/pull/1053
    // And: https://github.com/Moya/Moya/issues/1049
    private final class func url(for target: Target) -> URL {
        if target.path.isEmpty {
            return target.baseURL
        }

        return target.baseURL.appendingPathComponent(target.path)
    }
}
