import Foundation
import Result

@available(*, unavailable, renamed: "MoyaError", message: "Moya.Error has been renamed to MoyaError in version 8.0.0")
public typealias Error = MoyaError

extension Endpoint {
    @available(*, unavailable, renamed: "adding(newParameters:)")
    public func endpointByAddingParameters(parameters: [String: AnyObject]) -> Endpoint<Target> { fatalError() }

    @available(*, unavailable, renamed: "adding(newHTTPHeaderFields:)")
    public func endpointByAddingHTTPHeaderFields(httpHeaderFields: [String: String]) -> Endpoint<Target> { fatalError() }

    @available(*, unavailable, renamed: "adding(newParameterEncoding:)")
    public func endpointByAddingParameterEncoding(newParameterEncoding: Moya.ParameterEncoding) -> Endpoint<Target> { fatalError() }

    @available(*, unavailable, renamed: "adding(parameters:httpHeaderFields:parameterEncoding:)")
    public func endpointByAdding(parameters: [String: AnyObject]? = nil, httpHeaderFields: [String: String]? = nil, parameterEncoding: Moya.ParameterEncoding? = nil)  -> Endpoint<Target> { fatalError() }
}

@available(*, unavailable, renamed: "MultiTarget", message: "StructTarget has been renamed to MultiTarget in version 8.0.0")
enum StructTarget { }

extension MoyaProvider {
    @available(*, unavailable, renamed: "notifyPluginsOfImpendingStub(for:target:)")
    internal final func notifyPluginsOfImpendingStub(request: URLRequest, target: Target) { fatalError() }
}

extension Response {
    @available(*, unavailable, renamed: "filter(statusCodes:)")
    public func filterStatusCodes(range: ClosedRange<Int>) throws -> Response { fatalError() }

    @available(*, unavailable, renamed: "filter(statusCode:)")
    public func filterStatusCode(code: Int) throws -> Response { fatalError() }
}

extension PluginType {
    @available(*, unavailable, renamed: "willSend(_:)")
    func willSendRequest(request: RequestType, target: TargetType) { fatalError() }

    @available(*, unavailable, renamed: "didReceive(_:)")
    func didReceiveResponse(result: Result<Moya.Response, Moya.Error>, target: TargetType) { fatalError() }
}
