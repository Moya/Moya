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

    /// Provides stub data for use in testing.
    var sampleData: Data { get }

    /// The type of HTTP task to be performed.
    var task: Task { get }

    /// Whether or not to perform Alamofire validation. Defaults to `false`.
    var validate: Bool { get }

    // The headers to be used in the request.
    var headers: [String: String]? { get }
}

public extension TargetType {
    var defaultParameterEncoding: ParameterEncoding {
        return URLEncoding.default
    }

    var validate: Bool {
        return false
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
    case destination(DownloadDestination)

    /// Download a file to a destination with extra parameters using the given encoding.
    case parameters(DownloadDestination, parameters: [String: Any], encoding: ParameterEncoding)
}

/// Represents an HTTP task.
public enum Task {

    /// A requests body set with data.
    case requestData(Data)

    /// A requests body set with parameters and encoding.
    case requestParameters(parameters: [String: Any], encoding: ParameterEncoding)

    /// A requests body set with data, combined with url parameters.
    case requestCompositeData(urlParameters: [String: Any], bodyData: Data)

    /// A requests body set with parameters and encoding, combined with url parameters.
    case requestCompositeParameters(urlParameters: [String: Any], bodyParameters: [String: Any], bodyEncoding: ParameterEncoding)

    /// An upload task.
    case upload(UploadType)

    /// A download task.
    case download(DownloadType)
}

/// Extension to Parameter encoding to make using the `.requestEncoded` and `.requestCompositeEncoded` task types easier.
extension ParameterEncoding {
    static var `default`: ParameterEncoding {
        return JSONEncoding.default
    }
}
