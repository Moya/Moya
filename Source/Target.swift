import Foundation
import Alamofire

/// Protocol to define the base URL, path, method, parameters and sample data for a target.
public protocol TargetType {
    var baseURL: URL { get }
    var path: String { get }
    var method: Moya.Method { get }
    var parameters: [String: Any]? { get }
    var parameterEncoding: ParameterEncoding { get } // Defaults to `URLEncoding`
    var sampleData: Data { get }
    var task: Task { get }
    var validate: Bool { get } // Alamofire validation (defaults to `false`)
}

public extension TargetType {
    var parameterEncoding: ParameterEncoding {
        return URLEncoding.default
    }

    var validate: Bool {
        return false
    }
}

/// Represents an HTTP method.
public typealias Method = Alamofire.HTTPMethod

extension Method {
    public var supportsMultipart: Bool {
        switch self {
        case .post,
             .put,
             .patch,
             .connect:
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
