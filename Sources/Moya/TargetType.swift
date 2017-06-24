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

    /// The data to be passed alongside the request.
    var requestData: RequestData? { get }

    /// Provides stub data for use in testing.
    var sampleData: Data { get }

    /// The type of HTTP task to be performed.
    var task: Task { get }

    /// Whether or not to perform Alamofire validation. Defaults to `false`.
    var validate: Bool { get }
}

public extension TargetType {
    var validate: Bool {
        return false
    }
}

/// Represents the request data type.
public enum RequestData {
    /// Use `JSONEncoder` using its default configuration with an `Encodable` type.
    case json(Encodable)

    /// Use `JSONEncoder` using a custom configuration with an `Encodable` type.
    case jsonEncoder(Encodable, JSONEncoder)

    /// Use `PropertyListEncoder` using its default configuration with an `Encodable` type.
    case propertyList(Encodable)

    /// Use `PropertyListEncoder` using a custom configuration with an `Encodable` type.
    case propertyListEncoder(Encodable, PropertyListEncoder)

    /// Use Alamofire's parameters with a specified encoding.
    case parameterEncoding([String: Any], ParameterEncoding)
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
