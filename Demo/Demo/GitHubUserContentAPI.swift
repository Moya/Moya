import Foundation
import Moya

let GitHubUserContentProvider = MoyaProvider<GitHubUserContent>(plugins: [NetworkLoggerPlugin(verbose: true)])

public enum GitHubUserContent {
    case DownloadMoyaWebContent(String)
}

extension GitHubUserContent: TargetType {
    public var baseURL: NSURL { return NSURL(string: "https://raw.githubusercontent.com")! }
    public var path: String {
        switch self {
        case .DownloadMoyaWebContent(let contentPath):
            return "/Moya/Moya/master/web/\(contentPath)"
        }
    }
    public var method: Moya.Method {
        switch self {
        case .DownloadMoyaWebContent:
            return .GET
        }
    }
    public var parameters: [String: AnyObject]? {
        switch self {
        case .DownloadMoyaWebContent:
            return nil
        }
    }
    public var task: Task {
        switch self {
        case .DownloadMoyaWebContent:
            return .Download(.Request(DefaultDownloadDestination))
        }
    }
    public var sampleData: NSData {
        switch self {
        case .DownloadMoyaWebContent:
            return animatedBirdData()
        }
    }

}

private let DefaultDownloadDestination: DownloadDestination = { temporaryURL, response -> NSURL in
    let fileManager = NSFileManager.defaultManager()
    let directoryURLs = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
    let destination = directoryURLs[0].URLByAppendingPathComponent(response.suggestedFilename!)!
    //overwriting
    try! fileManager.removeItemAtURL(destination)
    return destination
}

