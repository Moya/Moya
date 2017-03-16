import Moya
import Foundation

extension String {
    var urlEscaped: String {
        return self.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
    }
}

enum GitHub {
    case zen
    case userProfile(String)
}

extension GitHub: TargetType {
    var baseURL: URL { return URL(string: "https://api.github.com")! }
    var path: String {
        switch self {
        case .zen:
            return "/zen"
        case .userProfile(let name):
            return "/users/\(name.urlEscaped)"
        }
    }
    
    var method: Moya.Method {
        return .get
    }
    
    var parameters: [String: Any]? {
        return nil
    }

    public var parameterEncoding: ParameterEncoding {
        return JSONEncoding.default
    }

    var task: Task {
        return .request
    }
    
    var sampleData: Data {
        switch self {
        case .zen:
            return "Half measures are as bad as nothing at all.".data(using: String.Encoding.utf8)!
        case .userProfile(let name):
            return "{\"login\": \"\(name)\", \"id\": 100}".data(using: String.Encoding.utf8)!
        }
    }
}

func url(_ route: TargetType) -> String {
    return route.baseURL.appendingPathComponent(route.path).absoluteString
}

let failureEndpointClosure = { (target: GitHub) -> Endpoint<GitHub> in
    let error = NSError(domain: "com.moya.moyaerror", code: 0, userInfo: [NSLocalizedDescriptionKey: "Houston, we have a problem"])
    return Endpoint<GitHub>(url: url(target), sampleResponseClosure: {.networkError(error)}, method: target.method, parameters: target.parameters)
}

enum HTTPBin: TargetType {
    case basicAuth

    var baseURL: URL { return URL(string: "http://httpbin.org")! }
    var path: String {
        switch self {
        case .basicAuth:
            return "/basic-auth/user/passwd"
        }
    }

    var method: Moya.Method {
        return .get
    }
    
    var parameters: [String: Any]? {
        switch self {
        default:
            return [:]
        }
    }

    var parameterEncoding: ParameterEncoding {
        return URLEncoding.default
    }
    
    var task: Task {
        return .request
    }
    
    var sampleData: Data {
        switch self {
        case .basicAuth:
            return "{\"authenticated\": true, \"user\": \"user\"}".data(using: String.Encoding.utf8)!
        }
    }
}

public enum GitHubUserContent {
    case downloadMoyaWebContent(String)
}

extension GitHubUserContent: TargetType {
    public var baseURL: URL { return URL(string: "https://raw.githubusercontent.com")! }
    public var path: String {
        switch self {
        case .downloadMoyaWebContent(let contentPath):
            return "/Moya/Moya/master/web/\(contentPath)"
        }
    }
    public var method: Moya.Method {
        switch self {
        case .downloadMoyaWebContent:
            return .get
        }
    }
    public var parameters: [String: Any]? {
        switch self {
        case .downloadMoyaWebContent:
            return nil
        }
    }
    public var parameterEncoding: ParameterEncoding {
        return URLEncoding.default
    }
    public var task: Task {
        switch self {
        case .downloadMoyaWebContent:
            return .download(.request(DefaultDownloadDestination))
        }
    }
    public var sampleData: Data {
        switch self {
        case .downloadMoyaWebContent:
            return Data(count: 4000)
        }
    }
   
}

private let DefaultDownloadDestination: DownloadDestination = { temporaryURL, response in
    let directoryURLs = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)

    if !directoryURLs.isEmpty {
        return (directoryURLs.first!.appendingPathComponent(response.suggestedFilename!), [])
    }
    
    return (temporaryURL, [])
}
