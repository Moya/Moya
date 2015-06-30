import Foundation
import Moya

// MARK: - Provider setup

let GitHubProvider = MoyaProvider<GitHub>()


// MARK: - Provider support

private extension String {
    var URLEscapedString: String {
        return self.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLHostAllowedCharacterSet())!
    }
}

public enum GitHub {
    case Zen
    case UserProfile(String)
    case UserRepositories(String)
}

extension GitHub : MoyaTarget {
    public var baseURL: NSURL { return NSURL(string: "https://api.github.com")! }
    public var path: String {
        switch self {
        case .Zen:
            return "/zen"
        case .UserProfile(let name):
            return "/users/\(name.URLEscapedString)"
        case .UserRepositories(let name):
            return "/users/\(name.URLEscapedString)/repos"
        }
    }
    public var method: Moya.Method {
        return .GET
    }
    public var parameters: [String: AnyObject] {
        switch self {
        case .UserRepositories(_):
            return ["sort": "pushed"]
        default:
            return [:]
        }
    }

    public var sampleData: NSData {
        switch self {
        case .Zen:
            return "Half measures are as bad as nothing at all.".dataUsingEncoding(NSUTF8StringEncoding)!
        case .UserProfile(let name):
            return "{\"login\": \"\(name)\", \"id\": 100}".dataUsingEncoding(NSUTF8StringEncoding)!
        case .UserRepositories(_):
            return "[{\"name\": \"Repo Name\"}]".dataUsingEncoding(NSUTF8StringEncoding)!
        }
    }
}

public func url(route: MoyaTarget) -> String {
    return route.baseURL.URLByAppendingPathComponent(route.path).absoluteString
}
