import Foundation
import Result

// MARK: - AccessTokenAuthorizable

/// A protocol for controlling the behavior of `AccessTokenPlugin`.
public protocol AccessTokenAuthorizable {

    /// Declares whether or not `AccessTokenPlugin` should add an authorization header
    /// to requests.
    var shouldAuthorize: Bool { get }
}

// MARK: - AccessTokenPlugin

/**
 A plugin for adding bearer-type authorization headers to requests. Example:

 ```
 Authorization: Bearer <token>
 ```

 - Note: By default, requests to all `TargetType`s will receive this header. You can control this
   behvaior by conforming to `AccessTokenAuthorizable`.
*/
public struct AccessTokenPlugin: PluginType {

    /// The access token to be applied in the header.
    public let token: String

    private var authVal: String {
        return "Bearer " + token
    }

    /**
     Initialize a new `AccessTokenPlugin`.

     - parameters:
       - token: The token to be applied in the pattern `Authorization: Bearer <token>`
    */
    public init(token: String) {
        self.token = token
    }

    /**
     Prepare a request by adding an authorization header if necessary.

     - parameters:
       - request: The request to modify.
       - target: The target of the request.
     - returns: The modified `URLRequest`.
    */
    public func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        if let authorizable = target as? AccessTokenAuthorizable, authorizable.shouldAuthorize == false {
            return request
        }

        var request = request
        request.addValue(authVal, forHTTPHeaderField: "Authorization")

        return request
    }
}
