import Moya
import Foundation

extension String {
    var URLEscapedString: String {
        return self.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLHostAllowedCharacterSet())!
    }
}

enum GitHub {
    case Zen
    case UserProfile(String)
}

extension GitHub: TargetType {
    var baseURL: NSURL { return NSURL(string: "https://api.github.com")! }
    var path: String {
        switch self {
        case .Zen:
            return "/zen"
        case .UserProfile(let name):
            return "/users/\(name.URLEscapedString)"
        }
    }
    var method: Moya.Method {
        return .GET
    }
    var parameters: [String: AnyObject]? {
        return nil
    }
    var sampleData: NSData {
        switch self {
        case .Zen:
            return "Half measures are as bad as nothing at all.".dataUsingEncoding(NSUTF8StringEncoding)!
        case .UserProfile(let name):
            return "{\"login\": \"\(name)\", \"id\": 100}".dataUsingEncoding(NSUTF8StringEncoding)!
        }
    }
}

func url(route: TargetType) -> String {
    return route.baseURL.URLByAppendingPathComponent(route.path).absoluteString
}

let failureEndpointClosure = { (target: GitHub) -> Endpoint<GitHub> in
    let error = NSError(domain: "com.moya.error", code: 0, userInfo: [NSLocalizedDescriptionKey: "Houston, we have a problem"])
    return Endpoint<GitHub>(URL: url(target), sampleResponseClosure: {.NetworkError(error)}, method: target.method, parameters: target.parameters)
}

enum HTTPBin: TargetType {
    case BasicAuth
    case MultipartPOST(NSData)

    var baseURL: NSURL { return NSURL(string: "http://httpbin.org")! }
    var path: String {
        switch self {
        case .BasicAuth:
            return "/basic-auth/user/passwd"
        case .MultipartPOST:
            return "/post"
        }
    }

    var method: Moya.Method {
        switch self {
        case .MultipartPOST:
            return .POST
        default:
            return .GET
        }
    }
    var parameters: [String: AnyObject]? {
        switch self {
        default:
            return [:]
        }
    }
    
    var requestType: TargetRequestType {
        switch self {
        case .MultipartPOST(_):
            return .Upload
        default:
            return .Request
        }
    }
    
    var uploadType: UploadType? {
        switch self {
        case .MultipartPOST(let data):
            return .Multipart({ formData in
                formData.appendBodyPart(data: data, name: "part_0_data")
            })
        default:
            return nil
        }
    }

    var sampleData: NSData {
        switch self {
        case .BasicAuth:
            return "{\"authenticated\": true, \"user\": \"user\"}".dataUsingEncoding(NSUTF8StringEncoding)!
        case .MultipartPOST:
            return "{\n  \"args\": {}, \n  \"data\": \"\", \n  \"files\": {}, \n  \"form\": {\n    \"part_0_data\": \"This is a multipart request!\"\n  }, \n  \"headers\": {\n    \"Accept\": \"*/*\", \n    \"Accept-Encoding\": \"gzip;q=1.0, compress;q=0.5\", \n    \"Accept-Language\": \"en;q=1.0\", \n    \"Content-Length\": \"164\", \n    \"Content-Type\": \"multipart/form-data; boundary=alamofire.boundary.c5630ddd0240ec4d\", \n    \"Host\": \"httpbin.org\"\n  }, \n  \"json\": null, \n  \"url\": \"http://httpbin.org/post\"\n}\n".dataUsingEncoding(NSUTF8StringEncoding)!
        }
    }
}
