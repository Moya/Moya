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

    /// The method used for parameter encoding.
    var parameterEncoding: ParameterEncoding { get }

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

    /**
     A helper function for loading `sampleData` from a file.
     
     - note: This traps when compiled in debug mode and the requested file cannot be loaded.

     - parameters:
       - fileName: The filename (without extension) containing the stubbed response.
       - ofType: The extension of the file containing the stubbed response. Defaults to "json".
       - inBundle: The `Bundle` to search in. Defaults to `Bundle.main`.
     - returns: The `Data` stored in the file or an empty `Data` if compiled in release mode and the requested file cannot be loaded.
    */
    public func stubbedResponse(forFileNamed fileName: String, ofType type: String = "json", inBundle bundle: Bundle = Bundle.main) -> Data {
        guard
            let url = bundle.url(forResource: fileName, withExtension: type),
            let data = try? Data(contentsOf: url)
        else {
            assert(false, "Unable to load stubbed response for \"\(fileName).\(type)\"")
            return Data()
        }

        return data
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
