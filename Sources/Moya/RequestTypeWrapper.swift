import Foundation

// Workaround for new asynchronous handling of Alamofire's request creation.
struct RequestTypeWrapper: RequestType {

    var request: URLRequest? { _urlRequest }

    var sessionHeaders: [String: String] { _request.sessionHeaders }

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
