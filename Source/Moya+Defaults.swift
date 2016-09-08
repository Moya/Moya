import Alamofire

/// These functions are default mappings to `MoyaProvider`'s properties: endpoints, requests, manager, etc.
public extension MoyaProvider {
    public final class func DefaultEndpointMapping(_ target: Target) -> Endpoint<Target> {
        let url = target.baseURL.appendingPathComponent(target.path)?.absoluteString
        return Endpoint(URL: url, sampleResponseClosure: {.NetworkResponse(200, target.sampleData)}, method: target.method, parameters: target.parameters)
    }

    public final class func DefaultRequestMapping(_ endpoint: Endpoint<Target>, closure: RequestResultClosure) {
        return closure(.Success(endpoint.urlRequest))
    }

    public final class func DefaultAlamofireManager() -> Manager {
        let configuration = URLSessionConfiguration.default
        configuration.HTTPAdditionalHeaders = Manager.defaultHTTPHeaders

        let manager = Manager(configuration: configuration)
        manager.startRequestsImmediately = false
        return manager
    }
}
