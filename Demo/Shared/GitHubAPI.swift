import Foundation
import Moya

// MARK: - Provider setup

private func JSONResponseDataFormatter(_ data: Data) -> Data {
    do {
        let dataAsJSON = try JSONSerialization.jsonObject(with: data)
        let prettyData =  try JSONSerialization.data(withJSONObject: dataAsJSON, options: .prettyPrinted)
        return prettyData
    } catch {
        return data // fallback to original data if it can't be serialized.
    }
}

let GitHubProvider = MoyaProvider<GitHub>(plugins: [NetworkLoggerPlugin(verbose: true, responseDataFormatter: JSONResponseDataFormatter)])

// MARK: - Provider support

private extension String {
    var urlEscaped: String {
        return self.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
    }
}

public enum GitHub {
    case zen
    case userProfile(String)
    case userRepositories(String)
}

extension GitHub: TargetType {
    public var baseURL: URL { return URL(string: "https://api.github.com")! }
    public var path: String {
        switch self {
        case .zen:
            return "/zen"
        case .userProfile(let name):
            return "/users/\(name.urlEscaped)"
        case .userRepositories(let name):
            return "/users/\(name.urlEscaped)/repos"
        }
    }
    public var method: Moya.Method {
        return .get
    }
    public var parameters: [String: Any]? {
        switch self {
        case .userRepositories(_):
            return ["sort": "pushed"]
        default:
            return nil
        }
    }
    public var parameterEncoding: ParameterEncoding {
        return URLEncoding.default
    }
    public var task: Task {
        return .request
    }
    public var validate: Bool {
        switch self {
        case .zen:
            return true
        default:
            return false
        }
    }
    public var sampleData: Data {
        switch self {
        case .zen:
            return "Half measures are as bad as nothing at all.".data(using: String.Encoding.utf8)!
        case .userProfile(let name):
            return "{\"login\": \"\(name)\", \"id\": 100}".data(using: String.Encoding.utf8)!
        case .userRepositories(_):
            return "[{\"name\": \"Repo Name\"}]".data(using: String.Encoding.utf8)!
        }
    }
}

public func url(_ route: TargetType) -> String {
    return route.baseURL.appendingPathComponent(route.path).absoluteString
}

//MARK: - Response Handlers

extension Moya.Response {
    func mapNSArray() throws -> NSArray {
        let any = try self.mapJSON()
        guard let array = any as? NSArray else {
            throw MoyaError.jsonMapping(self)
        }
        return array
    }
}

