import Foundation

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
    var validate: Bool {
        return false
    }
}

/// Represents an HTTP task.
public enum Task {

    /// A request with no additional data.
    case requestPlain

    /// A requests body set with data.
    case requestData(Data)

    /// A requests body set with parameters and encoding.
    case requestParameters(parameters: [String: Any], encoding: ParameterEncoding)

    /// A requests body set with data, combined with url parameters.
    case requestCompositeData(urlParameters: [String: Any], bodyData: Data)

    /// A requests body set with parameters and encoding, combined with url parameters.
    case requestCompositeParameters(urlParameters: [String: Any], bodyParameters: [String: Any], bodyEncoding: ParameterEncoding)

    /// A file upload task.
    case uploadFile(URL)

    /// A "multipart/form-data" upload task.
    case uploadMultipart([MultipartFormData])

    /// A file download task to a destination.
    case downloadDestination(DownloadDestination)

    /// A file download task to a destination with extra parameters using the given encoding.
    case downloadParameters(DownloadDestination, parameters: [String: Any], encoding: ParameterEncoding)
}
