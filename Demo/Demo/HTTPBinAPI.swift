import Foundation
import Moya


// MARK: - Provider Support

public enum HTTPBin {
    case MultipartPOST(NSData)
    case UploadFile(NSURL)
    case UploadData(NSData)
    case UploadStream(NSInputStream)
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
    public var requestType: TargetRequestType {
        return .Upload
    }
    public var uploadType: UploadType? {
        switch self {
        case .MultipartPOST(let data):
            return UploadType.Multipart({ formData in
                formData.appendBodyPart(data: data, name: "part_0_data")
            })
        case .UploadFile(let fileURL):
            return UploadType.File(fileURL)
        case .UploadData(let data):
            return UploadType.Data(data)
        case .UploadStream(let inputStream):
            return UploadType.Stream(inputStream)
        }
    }
    
    public var sampleData: NSData {
        return "Need to come up with something to represent the request!".dataUsingEncoding(NSUTF8StringEncoding)!
    }
}