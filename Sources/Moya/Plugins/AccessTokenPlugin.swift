import Foundation
import Result

/// HTTP authentication scheme
///
/// As declared in the [HTTP Authentication Scheme Registry](https://www.iana.org/assignments/http-authschemes/http-authschemes.xhtml)
public enum AuthenticationScheme {
    case basic
    case bearer

    var headerField: String {
        return "Authorization"
    }

    var tokenPrefix: String {
        switch self {
        case .basic:
            return "Basic"
        case .bearer:
            return "Bearer"
        }
    }
}

public enum TokenPlacement {
    case header
    case queryParameter
}

public enum AccessControlType {
    case none
    case http(scheme: AuthenticationScheme)
    case apiKey(name: String, placement: TokenPlacement)
}

public protocol AccessControllable {
    var accessControlType: AccessControlType { get }
}

public struct AccessTokenPlugin: PluginType {

    /// A closure returning the access token to be applied in the header or query parameter.
    public let tokenClosure: () -> String

    /// Initialize a new `AccessTokenPlugin`.
    ///
    /// - Parameter tokenClosure: A closure returning the token to be applied in the pattern `Authorization: <AuthenticationScheme> <token>`
    public init(tokenClosure: @escaping () -> String) {
        self.tokenClosure = tokenClosure
    }

    /// Prepare a request by adding an authorization header or query parameter if necessary.
    ///
    /// - Parameters:
    ///   - request: The request to modify.
    ///   - target: The target of the request.
    /// - Returns: The modified `URLRequest`.
    public func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        guard let accessControllable = target as? AccessControllable else { return request }

        var request = request

        switch accessControllable.accessControlType {
        case .http(let scheme):
            let authValue = scheme.tokenPrefix + " " + tokenClosure()
            request.addValue(authValue, forHTTPHeaderField: scheme.headerField)
        case .apiKey(let name, let placement) where placement == .header:
            request.addValue(tokenClosure(), forHTTPHeaderField: name)
        case .apiKey(let name, let placement) where placement == .queryParameter:
            guard let url = request.url else { return request }
            request.url = addOrAppendQueryParameterToURL(url, toParameter: name)
        default:
            break
        }

        return request
    }

    private func addOrAppendQueryParameterToURL(_ url: URL, toParameter name: String) -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return url }

        if components.queryItems != nil {
            // swiftlint:disable:next force_unwrapping
            components.queryItems!.append(URLQueryItem(name: name, value: tokenClosure()))
        } else {
            components.queryItems = [URLQueryItem(name: name, value: tokenClosure())]
        }

        do {
            return try components.asURL()
        } catch {
            return url
        }
    }
}
