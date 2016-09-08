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
            return .GET
        }
    }
    public var parameters: [String: AnyObject]? {
        switch self {
        case .downloadMoyaWebContent:
            return nil
        }
    }
    public var task: Task {
        switch self {
        case .downloadMoyaWebContent:
            return .Download(.Request(DefaultDownloadDestination))
        }
    }
    public var sampleData: Data {
        switch self {
        case .downloadMoyaWebContent:
            return animatedBirdData() as Data
        }
    }

}

private let DefaultDownloadDestination: DownloadDestination = { temporaryURL, response -> NSURL in
    let fileManager = NSFileManager.defaultManager()
    let directoryURLs = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
    let destination = directoryURLs[0].URLByAppendingPathComponent(response.suggestedFilename!)
    //overwriting
    try! fileManager.removeItemAtURL(destination)
    return destination
}

