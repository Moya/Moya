import Alamofire

/// These functions are default mappings to `MoyaProvider`'s properties: endpoints, requests, manager, etc.
public extension MoyaProvider {
    public final class func DefaultEndpointMapping(target: Target) -> Endpoint<Target> {
        guard let stringURL = target.baseURL.URLByAppendingPathComponent(target.path)?.absoluteString  else {
               fatalError("\(target) url is not valid")
        }
        return Endpoint(URL: stringURL, sampleResponseClosure: {.NetworkResponse(200, target.sampleData)}, method: target.method, parameters: target.parameters)
        /*
        if let url = target.baseURL.URLByAppendingPathComponent(target.path) {
            if let stringURL = url.absoluteString {
                return Endpoint(URL: url!, sampleResponseClosure: {.NetworkResponse(200, target.sampleData)}, method: target.method, parameters: target.parameters)
            }
        }
        fatalError("\(target) url is not valid")*/
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
