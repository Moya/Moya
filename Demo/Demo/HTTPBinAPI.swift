import Foundation
import Moya


// MARK: - Provider Support

public enum HTTPBin {
    case MultipartPOST
}

extension HTTPBin: TargetType {
    public var baseURL: NSURL { return NSURL(string: "http://httpbin.org")! }
    public var path: String {
        return "/post"
    }
    public var method: Moya.Method {
        return .POST
    }
    public var parameters: [String: AnyObject]? {
        return nil
    }
    
    public var sampleData: NSData {
        return "Need to come up with something to represent the request!".dataUsingEncoding(NSUTF8StringEncoding)!
    }
}