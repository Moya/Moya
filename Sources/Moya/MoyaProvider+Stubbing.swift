import Foundation

/// Mark: Stubbing

/// A TargetType configurable for testing responses
public protocol TestTargetType {

    var stubBehavior: Moya.StubBehavior { get }

    var sampleResponse: EndpointSampleResponse { get }

}

/// Controls how stub responses are returned.
public enum StubBehavior {

    /// Do not stub.
    case never

    /// Return a response immediately.
    case immediate

    /// Return a response after a delay.
    case delayed(seconds: TimeInterval)
}

extension MoyaProvider where Target: TestTargetType {

    // swiftlint:disable function_parameter_count
    /// When overriding this method, take care to `notifyPluginsOfImpendingStub` and to perform the stub using the `createStubFunction` method.
    /// Note: this was previously in an extension, however it must be in the original class declaration to allow subclasses to override.
    @discardableResult
    open func stubRequest(_ target: Target, request: URLRequest, callbackQueue: DispatchQueue?, completion: @escaping Moya.Completion, endpoint: Endpoint<Target>, stubBehavior: Moya.StubBehavior) -> CancellableToken {

        let callbackQueue = callbackQueue ?? self.callbackQueue
        let cancellableToken = CancellableToken { }
        notifyPluginsOfImpendingStub(for: request, target: target)

        let plugins = self.plugins
        let stub: () -> Void = createStubFunction(cancellableToken, forTarget: target, withCompletion: completion, endpoint: endpoint, plugins: plugins, request: request)

        switch stubBehavior {
        case .immediate:
            switch callbackQueue {
            case .none:
                stub()
            case .some(let callbackQueue):
                callbackQueue.async(execute: stub)
            }
        case .delayed(let delay):
            (callbackQueue ?? DispatchQueue.main).asyncAfter(deadline: .now() + delay) {
                stub()
            }
        case .never:
            fatalError("Method called to stub request when stubbing is disabled.")
        }

        return cancellableToken
    }
    // swiftlint:enable function_parameter_count

    /// Creates a function which, when called, executes the appropriate stubbing behavior for the given parameters.
    public final func createStubFunction(_ token: CancellableToken, forTarget target: Target, withCompletion completion: @escaping Moya.Completion, endpoint: Endpoint<Target>, plugins: [PluginType], request: URLRequest) -> (() -> Void) { // swiftlint:disable:this function_parameter_count
        return {

            guard !token.isCancelled else {
                self.cancelCompletion(completion, target: target)
                return
            }

            switch target.sampleResponse {
            case .networkResponse(let statusCode, let data):
                let response = Moya.Response(statusCode: statusCode, data: data, request: request, response: nil)
                plugins.forEach { $0.didReceive(.success(response), target: target) }
                completion(.success(response))
            case .response(let customResponse, let data):
                let response = Moya.Response(statusCode: customResponse.statusCode, data: data, request: request, response: customResponse)
                plugins.forEach { $0.didReceive(.success(response), target: target) }
                completion(.success(response))
            case .networkError(let error):
                let error = MoyaError.underlying(error, nil)
                plugins.forEach { $0.didReceive(.failure(error), target: target) }
                completion(.failure(error))
            }
        }
    }

    // swiftlint:disable:next function_parameter_count
    private func performRequest(_ target: Target, request: URLRequest, callbackQueue: DispatchQueue?, progress: Moya.ProgressBlock?, completion: @escaping Moya.Completion, endpoint: Endpoint<Target>) -> Cancellable {
        switch target.stubBehavior {
        case .never:
            return self.performNormalRequest(target, request: request, callbackQueue: callbackQueue, progress: progress, completion: completion, endpoint: endpoint)
        default:
            return self.stubRequest(target, request: request, callbackQueue: callbackQueue, completion: completion, endpoint: endpoint, stubBehavior: target.stubBehavior)
        }
    }

    /// Notify all plugins that a stub is about to be performed. You must call this if overriding `stubRequest`.
    final func notifyPluginsOfImpendingStub(for request: URLRequest, target: Target) {
        let alamoRequest = manager.request(request as URLRequestConvertible)
        plugins.forEach { $0.willSend(alamoRequest, target: target) }
        alamoRequest.cancel()
    }
}
