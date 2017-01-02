import Foundation
import Alamofire

/// The protocol used to define the specifications necessary for a `MoyaProvider`.
public protocol TargetType {

    /// The target's base `URL`.
    var baseURL: URL { get }

    /// The path to be appended to `baseURL` to form the full `URL`. Defaults to none.
    var path: String { get }

    /// The HTTP method used in the request. Defaults to `.get`.
    var method: Moya.Method { get }

    /// The parameters to be incoded in the request. Defaults to `nil`.
    var parameters: [String: Any]? { get }

    /// The method used for parameter encoding. Defaults to `URLEncoding`.
    var parameterEncoding: ParameterEncoding { get }

    /// Provides stub data for use in testing. Defaults to `Data()`.
    var sampleData: Data { get }

    /// The type of HTTP task to be performed. Defaults to `.request`.
    var task: Task { get }

    /// Whether or not to perform Alamofire validation. Defaults to `false`.
    var validate: Bool { get }
}

public extension TargetType {
    var path: String { return "" }
    var method: Moya.Method { return .get }
    var parameters: [String: Any]? { return nil }
    var parameterEncoding: ParameterEncoding { return URLEncoding.default }
    var sampleData: Data { return Data() }
    var task: Task { return .request }
    var validate: Bool { return false }
}

/// A `TargetType` that represents a GET request to a single `URL` with no parameters.
public struct SingleURLTarget: TargetType {
    public let baseURL: URL

    /// Initialize a SingleURLTarget
    public init(url: URL) {
        baseURL = url
    }
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
