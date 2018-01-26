import Foundation
import Alamofire

/// Represents "multipart/form-data" for an upload.
public struct MultipartFormData {

    /// Method to provide the form data.
    public enum FormDataProvider {
        case data(Foundation.Data)
        case file(URL)
        case stream(InputStream, UInt64)
    }

    public init(provider: FormDataProvider, name: String, fileName: String? = nil, mimeType: String? = nil) {
        self.provider = provider
        self.name = name
        self.fileName = fileName
        self.mimeType = mimeType
    }

    /// The method being used for providing form data.
    public let provider: FormDataProvider

    /// The name.
    public let name: String

    /// The file name.
    public let fileName: String?

    /// The MIME type
    public let mimeType: String?

}

// MARK: RequestMultipartFormData appending
internal extension RequestMultipartFormData {
    func append(data: Data, bodyPart: MultipartFormData) {
        if let mimeType = bodyPart.mimeType {
            if let fileName = bodyPart.fileName {
                append(data, withName: bodyPart.name, fileName: fileName, mimeType: mimeType)
            } else {
                append(data, withName: bodyPart.name, mimeType: mimeType)
            }
        } else {
            append(data, withName: bodyPart.name)
        }
    }

    func append(fileURL url: URL, bodyPart: MultipartFormData) {
        if let fileName = bodyPart.fileName, let mimeType = bodyPart.mimeType {
            append(url, withName: bodyPart.name, fileName: fileName, mimeType: mimeType)
        } else {
            append(url, withName: bodyPart.name)
        }
    }

    func append(stream: InputStream, length: UInt64, bodyPart: MultipartFormData) {
        append(stream, withLength: length, name: bodyPart.name, fileName: bodyPart.fileName ?? "", mimeType: bodyPart.mimeType ?? "")
    }

    func applyMoyaMultipartFormData(_ multipartBody: [Moya.MultipartFormData]) {
        for bodyPart in multipartBody {
            switch bodyPart.provider {
            case .data(let data):
                append(data: data, bodyPart: bodyPart)
            case .file(let url):
                append(fileURL: url, bodyPart: bodyPart)
            case .stream(let stream, let length):
                append(stream: stream, length: length, bodyPart: bodyPart)
            }
        }
    }
}
