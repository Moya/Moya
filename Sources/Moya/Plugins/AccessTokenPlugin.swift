import Foundation
import Result

// MARK: - AccessTokenAuthorizable

/// A protocol for controlling the behavior of `AccessTokenPlugin`.
public protocol AccessTokenAuthorizable {

    /// Represents the authorization header or url parameter to use for requests.
    var authorizationType: AuthorizationType { get }
}

// MARK: - AuthorizationType

/// An enum representing the header or url parameter to use with an `AccessTokenPlugin`
public enum AuthorizationType: String {
    case none
    case basic = "Basic"
    case bearer = "Bearer"
    case urlParameter = "access_token"
}

// MARK: - AccessTokenPlugin

/**
 A plugin for adding basic or bearer-type authorization headers, or url parameter to requests. Example:

 ```
 Authorization: Bearer <token>
 Authorization: Basic <token>
 access_token=<token>
 ```

*/
public struct AccessTokenPlugin: PluginType {

    /// A closure returning the access token to be applied in the header or url parameter.
    public let tokenClosure: () -> String

    /**
     Initialize a new `AccessTokenPlugin`.

     - parameters:
       - tokenClosure: A closure returning the token to be applied in the pattern `Authorization: <AuthorizationType> <token>` or `access_token=<token>`
    */
    public init(tokenClosure: @escaping @autoclosure () -> String) {
        self.tokenClosure = tokenClosure
    }

    /**
     Prepare a request by adding an authorization header or url parameter if necessary.

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
        case .basic, .bearer:
            let authValue = authorizationType.rawValue + " " + tokenClosure()
            request.addValue(authValue, forHTTPHeaderField: "Authorization")
          
        case .urlParameter:
          guard let requestUrl = request.url,
            var existingComponents = URLComponents(url: requestUrl, resolvingAgainstBaseURL: true)
            else { return request }
          
          let tokenQueryItem = URLQueryItem(name: authorizationType.rawValue, value: tokenClosure())
          var updatedQueryItems = [tokenQueryItem]
          
          if let currentQueryItems = existingComponents.queryItems {
            updatedQueryItems.append(contentsOf: currentQueryItems)
          }
          
          existingComponents.queryItems = updatedQueryItems
          request.url = existingComponents.url
          
        case .none:
            break
        }

        return request
    }
}
