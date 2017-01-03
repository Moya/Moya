import Foundation
import Result

// MARK: - AccessTokenAuthorizable

public protocol AccessTokenAuthorizable {
    var shouldAuthorize: Bool { get }
}

// MARK: - AccessTokenPlugin

public struct AccessTokenPlugin: PluginType {
    public let token: String

    private var authVal: String {
        return "Bearer " + token
    }

    public init(token: String) {
        self.token = token
    }

    public func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        if let authorizable = target as? AccessTokenAuthorizable, !authorizable.shouldAuthorize {
            return request
        }

        var request = request
        request.addValue(authVal, forHTTPHeaderField: "Authorization")

        return request
    }
}
