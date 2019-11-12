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
    }

    /// The given encodable will be encoded in the url's query.
    public struct URLParams {
        public var encodable: Encodable
        public var encoder: URLEncodedFormEncoder

        public init(_ encodable: Encodable, encoder: URLEncodedFormEncoder = URLEncodedFormEncoder()) {
            self.encodable = encodable
            self.encoder = encoder
        }
    }

    /// The given encodable will be encoded according to the given custom parameter encoder
    ///
    /// The provided encoder must not be a `URLEncodedFormParameterEncoder` (use `BodyParams.urlEncoded` or `URLParams`instead)
    /// or `JSONParameterEncoder`(use `BodyParams.json` instead). If this is the case, a `MoyaError.encodableMapping` will be raised.
    public struct CustomParams {
        public var encodable: Encodable
        public var encoder: ParameterEncoder

        public init(_ encodable: Encodable, encoder: ParameterEncoder) {
            self.encodable = encodable
            self.encoder = encoder
        }
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
    case request(
        bodyParams: BodyParams? = nil,
        urlParams: URLParams? = nil,
        customParams: [CustomParams]? = nil
    )

    /// A task to upload some data
    case upload(
        source: UploadSource,
        urlParams: URLParams? = nil,
        customParams: [CustomParams]? = nil
    )

    /// A task to download some data
    case download(
        destination: DownloadDestination,
        bodyParams: BodyParams? = nil,
        urlParam: URLParams? = nil,
        customParams: [CustomParams]? = nil
    )
}
