import Alamofire

/// These functions are default mappings to `MoyaProvider`'s properties: endpoints, requests, manager, etc.
public extension MoyaProvider {
    public final class func DefaultEndpointMapping(target: Target) -> Endpoint<Target> {
        guard let url = target.baseURL.URLByAppendingPathComponent(target.path).absoluteString != nil else {
            fatalError("\(target) url is invalid")
        }
        return Endpoint(URL: url, sampleResponseClosure: {.NetworkResponse(200, target.sampleData)}, method: target.method, parameters: target.parameters)
        //guard url = target.baseURL.URLByAppendingPathComponent(target.path).absoluteString != nil else {
        //}
        //if let url = target.baseURL.URLByAppendingPathComponent(target.path).absoluteString {
        //    return Endpoint(URL: url, sampleResponseClosure: {.NetworkResponse(200, target.sampleData)}, method: target.method, parameters: target.parameters)
        //}
    }

    public final class func DefaultRequestMapping(endpoint: Endpoint<Target>, closure: RequestResultClosure) {
        return closure(.Success(endpoint.urlRequest))
    }

    public final class func DefaultAlamofireManager() -> Manager {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.HTTPAdditionalHeaders = Manager.defaultHTTPHeaders

        let manager = Manager(configuration: configuration)
        manager.startRequestsImmediately = false
        return manager
    }
}
