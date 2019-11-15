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

    /// A container for some parameters to be encoded into an `URLRequest` using a specific encoder.
    public class Parameters {
        /// The given encodable will be encoded according to the given custom parameter encoder
        public let encodable: Encodable
        /// The encoder to be used to encode `encodable` into an `URLRequest`.
        public let encoder: ParameterEncoder

        internal init(encodable: Encodable, encoder: ParameterEncoder) {
            self.encodable = encodable
            self.encoder = encoder
        }
    }

    /// A container for some parameters to be encoded into an `URLRequest`'s url's query string using a specific encoder.
    public final class URLParams: Parameters {

        /// The designated method to initialize the `URLParams`.
        /// - Parameters:
        ///   - encodable: The parameters to be encoded into the url's query string.
        ///   - encoder: The encoder to be used to encode the encodable into the url's query string.
        public required init(_ encodable: Encodable, encoder: URLEncodedFormEncoder = URLEncodedFormEncoder()) {
            super.init(encodable: encodable, encoder: URLEncodedFormParameterEncoder(encoder: encoder, destination: .queryString))
        }
    }

    /// A container for some parameters to be encoded into an `URLRequest` using a specific encoder.
    public final class CustomParams: Parameters {

        /// The designated method to initialize `CustomParams`.
        /// - Parameters:
        ///   - encodable: The parameters to be encoded into the `URLRequest`.
        ///   - encoder: The encoder to be used to encode `encodable` into an `URLRequest`.
        ///   It **must not** be a `URLEncodedFormParameterEncoder` (use `BodyParams.urlEncoded`
        ///   or `URLParams` instead) or `JSONParameterEncoder`(use `BodyParams.json` instead).
        ///   If this is the case, a `MoyaError.encodableMapping` will be raised.
        public required init(_ encodable: Encodable, encoder: ParameterEncoder) throws {
            // CustomParams should only be used when `URLEncodedFormParameterEncoder` and `JSONParameterEncoder`
            // are not enough. To enforce usage of BodyParams or URLParams, let's check the type of the given encoder
            // to make sure CustomParams is correctly used.
            if encoder is JSONParameterEncoder {
                throw MoyaError.encodableMapping("A JSONParameterEncoder can not be used with Task.CustomParams. Use Task.BodyParams.json() instead.")
            }
            if encoder is URLEncodedFormParameterEncoder {
                throw MoyaError.encodableMapping("An URLEncodedFormParameterEncoder can not be used in Task.CustomParams. Use Task.BodyParams.urlEncoded() or Task.URLParams instead.")
            }
            super.init(encodable: encodable, encoder: encoder)
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
    case request(bodyParams: BodyParams? = nil, urlParams: URLParams? = nil, customParams: [CustomParams]? = nil)

    /// A task to upload some data
    case upload(source: UploadSource, urlParams: URLParams? = nil, customParams: [CustomParams]? = nil)

    /// A task to download some data
    case download(destination: DownloadDestination, bodyParams: BodyParams? = nil, urlParam: URLParams? = nil, customParams: [CustomParams]? = nil)
}
