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
public enum AuthorizationType {
    case none
    case basic
    case bearer
    case custom(headerField: String?, tokenPrefix: String?)
}

private extension AuthorizationType {
    static let defaultHeaderField = "Authorization"

    var headerField: String {
        switch self {
        case .basic, .bearer:
            return AuthorizationType.defaultHeaderField
        case .custom(let headerField, _):
            guard let headerField = headerField, !headerField.isEmpty else {
                return AuthorizationType.defaultHeaderField
            }
            return headerField
        case .none:
            return ""
        }
    }

    var tokenPrefix: String {
        switch self {
        case .basic:
            return "Basic "
        case .bearer:
            return "Bearer "
        case .custom(_, let tokenPrefix):
            guard let tokenPrefix = tokenPrefix, !tokenPrefix.isEmpty else {
                return ""
            }
            return tokenPrefix + " "
        case .none:
            return ""
        }
    }
}

// MARK: - AccessTokenPlugin

/**
 A plugin for adding basic or bearer-type authorization headers to requests. Example:

 ```
 Authorization: Bearer <token>
 Authorization: Basic <token>
 X-Access-Token: <token>
 ```

*/
public struct AccessTokenPlugin: PluginType {

    /// A closure returning the access token to be applied in the header.
    public let tokenClosure: () -> String

    /**
     Initialize a new `AccessTokenPlugin`.

     - parameters:
       - tokenClosure: A closure returning the token to be applied in the pattern `<HeaderField>: <AuthorizationType> <token>`
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
        case .basic, .bearer, .custom:
            let authValue = authorizationType.tokenPrefix + tokenClosure()
            request.addValue(authValue, forHTTPHeaderField: authorizationType.headerField)
        case .none:
            break
        }

        return request
    }
}
