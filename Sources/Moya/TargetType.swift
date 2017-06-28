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

    /// The default parameterEncoding for the `.encoded` RequestDataType case.
    var defaultParameterEncoding: ParameterEncoding { get }

    /// Provides stub data for use in testing.
    var sampleData: Data { get }

    /// The type of HTTP task to be performed.
    var task: Task { get }

    /// Whether or not to perform Alamofire validation. Defaults to `false`.
    var validate: Bool { get }
}

public extension TargetType {
    var defaultParameterEncoding: ParameterEncoding {
        return URLEncoding.default
    }

    var defaultJsonEncoder: JSONEncoder {
        return JSONEncoder()
    }

    var defaultPropertyListEncoder: PropertyListEncoder {
        return PropertyListEncoder()
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
    case encoded(DownloadDestination, parameters: [String: Any], encoding: ParameterEncoding)
}

/// Represents an HTTP task.
public enum Task {

    /// A basic request task.
    case request(RequestDataType)

    /// An upload task.
    case upload(UploadType)

    /// A download task.
    case download(DownloadType)
}

/// Represents a type of request.
public enum RequestDataType {
    /// A requests body set with data.
    case data(Data)

    /// A request body set as JSON from an encodable type with a JSONEncoder.
    case jsonEncodable(encodable: Encodable, encoder: JSONEncoder)

    /// A request body set as Property List from an encodable type with a PropertyListEncoder.
    case propertyListEncodable(encodable: Encodable, encoder: PropertyListEncoder)

    /// A requests body set with parameters and encoding.
    case encoded(parameters: [String: Any], encoding: ParameterEncoding)

    /// A requests body set with data, combined with url parameters.
    case compositeData(urlParameters: [String: Any], bodyData: Data)

    /// A request body set as JSON from an encodable type with a JSONEncoder, combined with url parameters
    case compositeJsonEncodable(urlParameters: [String: Any], encodable: Encodable, encoder: JSONEncoder)

    /// A request body set as Property List from an encodable type with a PropertyListEncoder, combined with url parameters
    case compositePropertyListEncodable(urlParameters: [String: Any], encodable: Encodable, encoder: PropertyListEncoder)

    /// A requests body set with parameters and encoding, combined with url parameters.
    case compositeEncoded(urlParameters: [String: Any], bodyParameters: [String: Any], bodyEncoding: ParameterEncoding)
}
