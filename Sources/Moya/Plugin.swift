import Foundation

/// A Moya Plugin receives callbacks to perform side effects wherever a request is sent or received.
///
/// for example, a plugin may be used to
///     - log network requests
///     - hide and show a network activity indicator
///     - inject additional information into a request
public protocol PluginType {
    /// Called to modify a request before sending.
    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest

    /// Called immediately before a request is sent over the network (or stubbed).
    func willSend(_ request: RequestType, target: TargetType)

    /// Called when the request is ready to be sent. Return a StubBehavior if you want your request to be stubbed,
    /// or `nil` to actually send the request over the network
    ///
    /// If a provider has more than 1 plugin returning a non nil value,only the value of the first of those plugins will be used.
    func stubBehavior(for target: TargetType) -> StubBehavior?

    /// Called after a response has been received, but before the MoyaProvider has invoked its completion handler.
    func didReceive(_ result: MoyaResult, target: TargetType)

    /// Called to modify a result before completion.
    func process(_ result: MoyaResult, target: TargetType) -> MoyaResult
}

public extension PluginType {
    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest { request }
    func willSend(_ request: RequestType, target: TargetType) { }
    func stubBehavior(for target: TargetType) -> StubBehavior? { nil }
    func didReceive(_ result: MoyaResult, target: TargetType) { }
    func process(_ result: MoyaResult, target: TargetType) -> MoyaResult { result }
}

/// Request type used by `willSend` plugin function.
public protocol RequestType {

    // Note:
    //
    // We use this protocol instead of the Alamofire request to avoid leaking that abstraction.
    // A plugin should not know about Alamofire at all.

    /// Retrieve an `NSURLRequest` representation.
    var request: URLRequest? { get }

    ///  Additional headers appended to the request when added to the session.
    var sessionHeaders: [String: String] { get }

    /// Authenticates the request with a username and password.
    func authenticate(username: String, password: String, persistence: URLCredential.Persistence) -> Self

    /// Authenticates the request with an `NSURLCredential` instance.
    func authenticate(with credential: URLCredential) -> Self

    /// cURL representation of the instance.
    ///
    /// - Returns: The cURL equivalent of the instance.
    func cURLDescription(calling handler: @escaping (String) -> Void) -> Self
}
