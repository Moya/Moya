import Foundation
import Alamofire

/// The protocol used to define the specifications necessary for a `MoyaProvider`.
public protocol TargetType {

    /// The target's base `URL`.
    var baseURL: URL { get }

    /// The path to be appended to `baseURL` to form the full `URL`.
    var path: String { get }

    /// The HTTP method used in the request.
    var method: Moya.Method { get }

    /// The parameters to be incoded in the request.
    var parameters: [String: Any]? { get }

    /// The method used for parameter encoding. Defaults to `URLEncoding`.
    var parameterEncoding: ParameterEncoding { get }

    /// Provides stub data for use in testing.
    var sampleData: Data { get }

    /// The type of HTTP task to be performed.
    var task: Task { get }

    /// Whether or not to perform Alamofire validation. Defaults to `false`.
    var validate: Bool { get }
}

public extension TargetType {
    var parameterEncoding: ParameterEncoding {
        return URLEncoding.default
    }

    var validate: Bool {
        return false
    }
}

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

/// Controls stub responses are returned.
public enum StubBehavior {

    /// Never return  a response.
    case never

    /// Return a response immediately.
    case immediate

    /// Return a response after a delay.
    case delayed(seconds: TimeInterval)
}

/// Represents a type of upload task.
public enum UploadType {

    /// Upload a file.
    case file(URL)

    /// Upload "multipart/form-data"
    case multipart([MultipartFormData])
}

/// Represents a type of download task.
public enum DownloadType {

    /// Download a file to a destination.
    case request(DownloadDestination)
}

/// Represents an HTTP task.
public enum Task {

    /// A basic request task.
    case request

    /// An upload task.
    case upload(UploadType)

    /// A download task.
    case download(DownloadType)
}
