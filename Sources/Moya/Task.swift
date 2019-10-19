import Foundation

/// Represents an HTTP task.
public enum Task {

    public typealias TaskParameters = [(ParameterEncoder, Encodable)]

    /// A task to request some data
    case request(body: Data?, params: TaskParameters?)

    /// A task to upload some data
    case uploadData(Data)

    /// A task for upload a file
    case uploadFile(URL)

    /// A "multipart/form-data" upload task.
    case uploadMultiPart([MultipartFormData], params: TaskParameters?)

    ///
    case download(destination: DownloadDestination, params: TaskParameters?)

    // MARK: Convenience ways to get a NewTask

    // If the given parameters conflict (for example by providing either `httpBodyParams` and `jsonParams`),
    // only the lastest in parameters order will be used.
    public static func request(bodyData: Data? = nil,
                               methodDependentParams methodDependantEncodable: Encodable? = nil,
                               httpBodyParams bodyEncodable: Encodable? = nil,
                               queryParams queryEncodable: Encodable? = nil,
                               jsonParams jsonEncodable: Encodable? = nil,
                               customParams: TaskParameters? = nil) -> Task {
        var finalParams: TaskParameters = []

        if let encodable = methodDependantEncodable {
            finalParams.append((URLEncodedFormParameterEncoder.default, encodable))
        }

        if let encodable = bodyEncodable {
            finalParams.append((URLEncodedFormParameterEncoder(destination: .httpBody), encodable))
        }

        if let encodable = queryEncodable {
            finalParams.append((URLEncodedFormParameterEncoder(destination: .queryString), encodable))
        }

        if let encodable = jsonEncodable {
            finalParams.append((JSONParameterEncoder.default, encodable))
        }

        if let customParams = customParams {
            finalParams.append(contentsOf: customParams)
        }

        //Avoid passing empty arrays
        if finalParams.isEmpty {
            return .request(body: bodyData, params: nil)
        } else {
            return .request(body: bodyData, params: finalParams)
        }
    }

    public static func uploadMultipart(_ multiPart: [MultipartFormData],
                                       queryParamsEncoder: URLEncodedFormParameterEncoder = .default,
                                       queryParams queryEncodable: Encodable? = nil) -> Task {
        var finalParams: TaskParameters?
        if let encodable = queryEncodable {
            finalParams = [(queryParamsEncoder, encodable)]
        }
        return .uploadMultiPart(multiPart, params: finalParams)
    }

    public static func download(to destination: @escaping DownloadDestination,
                                paramsEncoder: ParameterEncoder = URLEncodedFormParameterEncoder.default,
                                params: Encodable? = nil) -> Task {
        var finalParams: TaskParameters?
        if let encodable = params {
            finalParams = [(paramsEncoder, encodable)]
        }
        return .download(destination: destination, params: finalParams)
    }
}
