import Foundation

/// Protocol to define the base URL, path, method, parameters and sample data for a target.
public protocol TargetType {
    var baseURL: URL { get }
    var path: String { get }
    var method: Moya.Method { get }
    var parameters: [String: Any]? { get }
    var sampleData: Data { get }
    var task: Task { get }
}

public enum StructTarget: TargetType {
    case `struct`(TargetType)

    public init(_ target: TargetType) {
        self = StructTarget.struct(target)
    }

    public var path: String {
        return target.path
    }

    public var baseURL: URL {
        return target.baseURL
    }

    public var method: Moya.Method {
        return target.method
    }

    public var parameters: [String: Any]? {
        return target.parameters
    }

    public var sampleData: Data {
        return target.sampleData
    }
    public var task: Task {
        return target.task
    }

    public var target: TargetType {
        switch self {
        case .struct(let t): return t
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
    case never
    case immediate
    case delayed(seconds: TimeInterval)
}

public enum UploadType {
    case file(URL)
    case multipart([MultipartFormData])
}

public enum DownloadType {
    case request(DownloadDestination)
}

public enum Task {
    case request
    case upload(UploadType)
    case download(DownloadType)
}

public struct MultipartFormData {
    public enum FormDataProvider {
        case data(Foundation.Data)
        case file(URL)
        case stream(InputStream, UInt64)
    }

    public init(provider: FormDataProvider, name: String, fileName: String? = nil, mimeType: String? = nil) {
        self.provider = provider
        self.name = name
        self.fileName = fileName
        self.mimeType = mimeType
    }

    public let provider: FormDataProvider
    public let name: String
    public let fileName: String?
    public let mimeType: String?
}
