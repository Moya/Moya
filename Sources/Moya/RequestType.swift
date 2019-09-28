import Foundation

/// An abstraction layer on top of URLRequest with complementary fields and functions.
public protocol RequestType {

    // Note:
    //
    // We use this protocol instead of the Alamofire request to avoid leaking that abstraction.
    // Users shouldn't know about Alamofire at all.

    /// Retrieve an `NSURLRequest` representation.
    var request: URLRequest? { get }

    /// Number of times the `RequestType` has been retried.
    var retryCount: Int { get }

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

// Workaround for new asynchronous handling of Alamofire's request creation.
struct RequestTypeWrapper: RequestType {

    var request: URLRequest? {
        return _urlRequest
    }

    var retryCount: Int {
        return _request.retryCount
    }

    var sessionHeaders: [String: String] {
        return _request.sessionHeaders
    }

    private var _request: Request
    private var _urlRequest: URLRequest?

    init(request: Request, urlRequest: URLRequest?) {
        self._request = request
        self._urlRequest = urlRequest
    }

    func authenticate(username: String, password: String, persistence: URLCredential.Persistence) -> RequestTypeWrapper {
        let newRequest = _request.authenticate(username: username, password: password, persistence: persistence)
        return RequestTypeWrapper(request: newRequest, urlRequest: _urlRequest)
    }

    func authenticate(with credential: URLCredential) -> RequestTypeWrapper {
        let newRequest = _request.authenticate(with: credential)
        return RequestTypeWrapper(request: newRequest, urlRequest: _urlRequest)
    }

    func cURLDescription(calling handler: @escaping (String) -> Void) -> RequestTypeWrapper {
        _request.cURLDescription(calling: handler)
        return self
    }
}
