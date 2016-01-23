import Foundation

public class MoyaProviderBackend: MoyaProviderBackendType {
    public let manager: Manager

    public init(manager: Manager = DefaultAlamofireManager()) {
        self.manager = manager
    }

    public func request(target: TargetType,
                        endpoint: Endpoint,
                        request: NSURLRequest,
                        plugins: [PluginType],
                        completion: Moya.Completion) -> CancellableToken {
        let alamoRequest = manager.request(request)

        // Give plugins the chance to alter the outgoing request
        plugins.forEach { $0.willSendRequest(alamoRequest, target: target) }

        // Perform the actual request
        alamoRequest.response { (_, response: NSHTTPURLResponse?, data: NSData?, error: NSError?) -> () in
            let result = convertResponseToResult(response, data: data, error: error)
            // Inform all plugins about the response
            plugins.forEach { $0.didReceiveResponse(result, target: target) }
            completion(result: result)
        }

        alamoRequest.resume()

        return CancellableToken(request: alamoRequest)
    }
}

public class MoyaProviderStubBackend: MoyaProviderBackendType {
    public let manager: Manager
    public let stubBehavior: StubBehavior

    public init(stubBehavior: StubBehavior = .Immediate, manager: Manager = DefaultAlamofireManager()) {
        self.manager = manager
        self.stubBehavior = stubBehavior
    }

    /// When overriding this method, take care to `notifyPluginsOfImpendingStub` and to perform the stub using the `createStubFunction` method.
    /// Note: this was previously in an extension, however it must be in the original class declaration to allow subclasses to override.
    public func request(target: TargetType,
                        endpoint: Endpoint,
                        request: NSURLRequest,
                        plugins: [PluginType],
                        completion: Moya.Completion) -> CancellableToken {
        let cancellableToken = CancellableToken { }
        notifyPluginsOfImpendingStub(request, target: target, plugins: plugins)
        let stub: () -> () = createStubFunction(cancellableToken, forTarget: target, endpoint: endpoint, plugins: plugins, withCompletion: completion)
        switch self.stubBehavior {
        case .Immediate:
            stub()
        case .Delayed(let delay):
            let killTimeOffset = Int64(CDouble(delay) * CDouble(NSEC_PER_SEC))
            let killTime = dispatch_time(DISPATCH_TIME_NOW, killTimeOffset)
            dispatch_after(killTime, dispatch_get_main_queue()) {
                stub()
            }
        case .Never:
            fatalError("Method called to stub request when stubbing is disabled.")
        }

        return cancellableToken
    }

    /// Creates a function which, when called, executes the appropriate stubbing behavior for the given parameters.
    internal final func createStubFunction(token: CancellableToken,
                                           forTarget target: TargetType,
                                           endpoint: Endpoint,
                                           plugins: [PluginType],
                                           withCompletion completion: Moya.Completion) -> (() -> ()) {
        return {
            if (token.canceled) {
                let error = Moya.Error.Underlying(NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled, userInfo: nil))
                plugins.forEach { $0.didReceiveResponse(.Failure(error), target: target) }
                completion(result: .Failure(error))
                return
            }

            switch endpoint.sampleResponseClosure() {
            case .NetworkResponse(let statusCode, let data):
                let response = Moya.Response(statusCode: statusCode, data: data, response: nil)
                plugins.forEach { $0.didReceiveResponse(.Success(response), target: target) }
                completion(result: .Success(response))
            case .NetworkError(let error):
                let error = Moya.Error.Underlying(error)
                plugins.forEach { $0.didReceiveResponse(.Failure(error), target: target) }
                completion(result: .Failure(error))
            }
        }
    }

    /// Notify all plugins that a stub is about to be performed. You must call this if overriding `stubRequest`.
    internal final func notifyPluginsOfImpendingStub(request: NSURLRequest, target: TargetType, plugins: [PluginType]) {
        let alamoRequest = manager.request(request)
        plugins.forEach { $0.willSendRequest(alamoRequest, target: target) }
    }
}
