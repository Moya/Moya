import Foundation

/// Represents an HTTP task.
public enum Task {

    /// All different ways to set parameters in an HTTP request's body.
    public enum BodyParams {
        /// The given encodable will be set in the request's body without any additional encoding.
        case raw(Data)

        /// The given encodable will be json encoded in the request's body.
        case json(Encodable, JSONEncoder = JSONEncoder())

        /// The given encodable will be url encoded in the request's body.
        case urlEncoded(Encodable, URLEncodedFormEncoder = URLEncodedFormEncoder())

        /// The given encodable will be encoded in the request's body using the provided encoder.
        ///
        /// The provided encoder must not be a `URLEncodedFormParameterEncoder` (use `BodyParams.urlEncoded`instead)
        /// or `JSONParameterEncoder`(use `BodyParams.json` instead). If this is the case, a `MoyaError.encodableMapping` will be raised.
        case custom(Encodable, ParameterEncoder)
    }

    /// All different ways to set parameters in an HTTP request's query.
    public enum QueryParams {
        /// The given encodable will be url encoded in the request's query.
        case query(Encodable, URLEncodedFormEncoder = URLEncodedFormEncoder())
    }

    /// All sources available for use when uploading
    public enum UploadSource {
        /// Upload the provided data
        case rawData(Data)

        /// Upload the file at the given url
        case file(URL)

        /// Upload some multipart content.
        case multipart([MultipartFormData])
    }

    /// A task to request some data
    case request(bodyParams: BodyParams? = nil, queryParams: QueryParams? = nil)

    /// A task to upload some data
    case upload(source: UploadSource, bodyParams: BodyParams? = nil, queryParams: QueryParams? = nil)

    /// A task to download some data
    case download(destination: DownloadDestination, bodyParams: BodyParams? = nil, queryParams: QueryParams? = nil)
}
