import Foundation

/// Represents an HTTP task.
public enum Task {

    public enum BodyParams {
        case raw(Data)
        case json(Encodable, JSONParameterEncoder = .default)
        case urlEncoded(Encodable, URLEncodedFormParameterEncoder = .init(destination: .httpBody))
        case custom(Encodable, ParameterEncoder)
    }

    public enum QueryParams {
        case query(Encodable, URLEncodedFormParameterEncoder = .init(destination: .queryString))
    }

    public enum UploadSource {
        case rawData(Data)
        case file(URL)
        case multipart([MultipartFormData])
    }

    /// A task to request some data
    case request(bodyParams: BodyParams? = nil, queryParams: QueryParams? = nil)

    /// A task to upload some data
    case upload(source: UploadSource, bodyParams: BodyParams? = nil, queryParams: QueryParams? = nil)

    /// A task to download some data
    case download(destination: DownloadDestination, bodyParams: BodyParams? = nil, queryParams: QueryParams? = nil)
}

public extension Task {
    typealias TaskParameters = (Encodable, ParameterEncoder)

    var allParameters: [TaskParameters] {
        switch self {
        case let .request(bodyParams, queryParams),
             let .upload(_, bodyParams, queryParams),
             let .download(_, bodyParams, queryParams):
            return [bodyParams?.taskParameters, queryParams?.taskParameters].compactMap { $0 }
        }
    }
}
