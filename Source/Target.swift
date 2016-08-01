import Foundation

/// Protocol to define the base URL, path, method, parameters and sample data for a target.
public protocol TargetType {
    var baseURL: NSURL { get }
    var path: String { get }
    var method: Moya.Method { get }
    var parameters: [String: AnyObject]? { get }
    var sampleData: NSData { get }
    var task: Task { get }
}

public enum StructTarget: TargetType {
    case Struct(TargetType)

    public init(_ target: TargetType) {
        self = StructTarget.Struct(target)
    }

    public var path: String {
        return target.path
    }

    public var baseURL: NSURL {
        return target.baseURL
    }

    public var method: Moya.Method {
        return target.method
    }

    public var parameters: [String: AnyObject]? {
        return target.parameters
    }

    public var sampleData: NSData {
        return target.sampleData
    }
    public var task: Task {
        return target.task
    }

    public var target: TargetType {
        switch self {
        case .Struct(let t): return t
        }
    }
}

/// Represents an HTTP method.
public enum Method: String {
    case GET, POST, PUT, DELETE, OPTIONS, HEAD, PATCH, TRACE, CONNECT

    public var supportsMultipart: Bool {
        switch self {
        case .POST,
             .PUT,
             .PATCH,
             .CONNECT:
            return true
        default:
            return false
        }
    }
}

public enum StubBehavior {
    case Never
    case Immediate
    case Delayed(seconds: NSTimeInterval)
}

public enum UploadType {
    case File(NSURL)
    case Multipart([MultipartFormData])
}

public enum DownloadType {
    case Request(DownloadDestination)
}

public enum Task {
    case Request
    case Upload(UploadType)
    case Download(DownloadType)
}

public struct MultipartFormData {
    public enum FormDataProvider {
        case Data(NSData)
        case File(NSURL)
        case Stream(NSInputStream, UInt64)
    }

    public init(provider: FormDataProvider, name: String, fileName: String = "", mimeType: String = "") {
        self.provider = provider
        self.name = name
        self.fileName = fileName
        self.mimeType = mimeType
    }

    public let provider: FormDataProvider
    public let name: String
    public let fileName: String
    public let mimeType: String
}
