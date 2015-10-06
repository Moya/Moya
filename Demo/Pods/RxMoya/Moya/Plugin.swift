import Foundation

/// A Moya Plugin receives callbacks to perform side effects wherever a request is sent or received.
///
/// for example, a plugin may be used to
///     - log network requests
///     - hide and show a network avtivity indicator 
///     - inject additional information into a request
public class Plugin<Target: MoyaTarget> {
    
    // NOTE:
    //
    // We cannot implement `Plugin` as a generic protocol here, because `MoyaProvider` needs
    // to keep references to an array of plugins and a generic protocol cannot be used as an array constraint.
    //
    // i.e.
    // protocol Plugin {
    //      typealias T: MoyaTarget
    //      ...
    // }
    //
    // let plugins = [Plugin]()
    // 
    // This does not work, because `plugins` is now unable to infer the actual type of the typealias `T`.

    /// Called immediately before a request is sent over the network (or stubbed).
    func willSendRequest(request: MoyaRequest, provider: MoyaProvider<Target>, target: Target) {
        // Should be overridden if necessary
    }

    // Called after a response has been received, but before the MoyaProvider has invoked its completion handler.
    func didReceiveResponse(data: NSData?, statusCode: Int?, response: NSURLResponse?, error: ErrorType?, provider: MoyaProvider<Target>, target: Target) {
        // Should be overridden if necessary
    }
}

/// Request type used by willSendRequest plugin function.
public protocol MoyaRequest {

    // Note:
    //
    // We use this protocol instead of the Alamofire request to avoid leaking that abstraction. 
    // A plugin should not know about Alamofire at all.

    /// Retrieve an NSURLRequest represetation.
    var request: NSURLRequest? { get }

    /// Authenticates the request with a username and password.
    func authenticate(user user: String, password: String, persistence: NSURLCredentialPersistence) -> Self

    /// Authnenticates the request with a NSURLCredential instance.
    func authenticate(usingCredential credential: NSURLCredential) -> Self
}
