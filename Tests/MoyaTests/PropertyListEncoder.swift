import Alamofire
import Foundation

internal struct PropertyListEncoder: ParameterEncoder {

    // MARK: Properties
    /// Returns a default `PropertyListEncoder` instance.
    static var `default`: PropertyListEncoder { return PropertyListEncoder() }

    /// Returns a `PropertyListEncoder` instance with xml formatting and default writing options.
    static var xml: PropertyListEncoder { return PropertyListEncoder(format: .xml) }

    /// Returns a `PropertyListEncoder` instance with binary formatting and default writing options.
    static var binary: PropertyListEncoder { return PropertyListEncoder(format: .binary) }

    /// The property list serialization format.
    let format: PropertyListSerialization.PropertyListFormat

    /// The options for writing the parameters as plist data.
    let options: PropertyListSerialization.WriteOptions

    // MARK: Initialization
    /// Creates a `PropertyListEncoder` instance using the specified format and options.
    ///
    /// - parameter format:  The property list serialization format.
    /// - parameter options: The options for writing the parameters as plist data.
    ///
    /// - returns: The new `PropertyListEncoder` instance.
    init(
        format: PropertyListSerialization.PropertyListFormat = .xml,
        options: PropertyListSerialization.WriteOptions = 0) {
        self.format = format
        self.options = options
    }

    // MARK: Encoding
    /// Creates a URL request by encoding parameters and applying them onto an existing request.
    ///
    /// - parameter urlRequest: The request to have parameters applied.
    /// - parameter parameters: The parameters to apply.
    ///
    /// - throws: An `Error` if the encoding process encounters an error.
    ///
    /// - returns: The encoded request.
    func encode<Parameters>(_ parameters: Parameters?, into request: URLRequest) throws -> URLRequest where Parameters : Encodable {

        var urlRequest = try request.asURLRequest()

        guard let parameters = parameters else { return urlRequest }

        do {
            let data = try PropertyListSerialization.data(
                fromPropertyList: parameters,
                format: format,
                options: options
            )

            if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
                urlRequest.setValue("application/x-plist", forHTTPHeaderField: "Content-Type")
            }

            urlRequest.httpBody = data
        } catch {
            throw AFError.parameterEncoderFailed(reason: AFError.ParameterEncoderFailureReason.encoderFailed(error: error))
        }

        return urlRequest
    }
}
