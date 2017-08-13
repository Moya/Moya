import Foundation
import Result

// MARK: - AccessTokenAuthorizable

/// A protocol for controlling the behavior of `AccessTokenPlugin`.
public protocol AccessTokenAuthorizable {

    /// Represents the authorization header to use for requests.
    var authorizationType: AuthorizationType { get }
}

// MARK: - AuthorizationType

/// An enum representing the header to use with an `AccessTokenPlugin`
public enum AuthorizationType: String {
    case none
    case basic = "Basic "
    case bearer = "Bearer "
}

// MARK: - AccessTokenPlugin

/**
 A plugin for adding basic or bearer-type authorization headers to requests. Example:

 ```
 Authorization: Bearer <token>
 Authorization: Basic <token>
 ```

 - Note: By default, requests to all `TargetType`s will receive this header. You can control this
   behavior by conforming to `AccessTokenAuthorizable`.
*/
public struct AccessTokenPlugin: PluginType {

    /// A closure returning the access token to be applied in the header.
    public let tokenClosure: () -> String

    /**
     Initialize a new `AccessTokenPlugin`.

     - parameters:
       - tokenClosure: A closure returning the token to be applied in the pattern `Authorization: <AuthorizationType> <token>`
    */
    public init(tokenClosure: @escaping @autoclosure () -> String) {
        self.tokenClosure = tokenClosure
    }

    /**
     Prepare a request by adding an authorization header if necessary.

     - parameters:
       - request: The request to modify.
       - target: The target of the request.
     - returns: The modified `URLRequest`.
    */
    public func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        guard let authorizable = target as? AccessTokenAuthorizable else { return request }

        let authorizationType = authorizable.authorizationType

        var request = request

        switch authorizationType {
        case .basic:
            request.addValue(authorizationType.rawValue + tokenClosure(), forHTTPHeaderField: "Authorization")
        case .bearer:
            request.addValue(authorizationType.rawValue + tokenClosure(), forHTTPHeaderField: "Authorization")
        case .none:
            break
        }

        return request
    }
}
