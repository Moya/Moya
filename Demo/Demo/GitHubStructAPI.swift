import Foundation
import Moya

let GitHubStructProvider = MoyaProvider<GitHubStruct>(plugins: [NetworkLoggerPlugin(verbose: true, responseDataFormatter: JSONResponseDataFormatter)])

public enum GitHubStruct: ServiceType {
    case Zen(ZenResource)
}

public struct ZenResource: TargetType {
    public let path = "/zen"
    public let baseURL = NSURL(string: "https://api.github.com")!
    public let method: Moya.Method = .GET
    public let parameters: [String: AnyObject]? = nil
    public let sampleData = "Half measures are as bad as nothing at all.".dataUsingEncoding(NSUTF8StringEncoding)!
}
