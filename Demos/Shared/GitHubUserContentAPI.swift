import Foundation
import Moya

let GitHubUserContentProvider = MoyaProvider<GitHubUserContent>(plugins: [NetworkLoggerPlugin(verbose: true)])

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
            return animatedBirdData() as Data
        }
    }

}

private let DefaultDownloadDestination: DownloadDestination = { temporaryURL, response in
    let directoryURLs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    
    if !directoryURLs.isEmpty {
        return (directoryURLs[0].appendingPathComponent(response.suggestedFilename!), [])
    }
    
    return (temporaryURL, [])
}

