import Moya

#if canImport(UIKit)
    import UIKit
    import Foundation
#elseif canImport(AppKit)
    import AppKit
#endif

// MARK: - Mock Services
enum GitHub {
    case zen
    case userProfile(String)
}

extension GitHub: TargetType {
    var baseURL: URL { return URL(string: "https://api.github.com")! }
    var path: String {
        switch self {
        case .zen:
            return "/zen"
        case .userProfile(let name):
            return "/users/\(name.urlEscaped)"
        }
    }

    var method: Moya.Method {
        return .get
    }

    var task: Task {
        return .requestPlain
    }

    var sampleData: Data {
        switch self {
        case .zen:
            return "Half measures are as bad as nothing at all.".data(using: String.Encoding.utf8)!
        case .userProfile(let name):
            return "{\"login\": \"\(name)\", \"id\": 100}".data(using: String.Encoding.utf8)!
        }
    }

    var validationType: ValidationType {
        return .successAndRedirectCodes
    }

    var headers: [String: String]? {
        return nil
    }
}

extension GitHub: Equatable {
    static func == (lhs: GitHub, rhs: GitHub) -> Bool {
        switch (lhs, rhs) {
        case (.zen, .zen): return true
        case let (.userProfile(username1), .userProfile(username2)): return username1 == username2
        default: return false
        }
    }
}

func url(_ route: TargetType) -> String {
    return route.baseURL.appendingPathComponent(route.path).absoluteString
}

let failureEndpointClosure = { (target: GitHub) -> Endpoint in
    let error = NSError(domain: "com.moya.moyaerror", code: 0, userInfo: [NSLocalizedDescriptionKey: "Houston, we have a problem"])
    return Endpoint(url: url(target), sampleResponseClosure: {.networkError(error)}, method: target.method, task: target.task, httpHeaderFields: target.headers)
}

enum HTTPBin: TargetType, AccessTokenAuthorizable {
    case basicAuth
    case bearer
    case post
    case upload(file: URL)
    case uploadMultipart([MultipartFormData], [String: Any]?)
    case validatedUploadMultipart([MultipartFormData], [String: Any]?, [Int])

    var baseURL: URL { return URL(string: "http://httpbin.org")! }
    var path: String {
        switch self {
        case .basicAuth:
            return "/basic-auth/user/passwd"
        case .bearer:
            return "/bearer"
        case .post, .upload, .uploadMultipart, .validatedUploadMultipart:
            return "/post"
        }
    }

    var method: Moya.Method {
        switch self {
        case .basicAuth, .bearer:
            return .get
        case .post, .upload, .uploadMultipart, .validatedUploadMultipart:
            return .post
        }
    }

    var task: Task {
        switch self {
        case .basicAuth, .post, .bearer:
            return .requestParameters(parameters: [:], encoding: URLEncoding.default)
        case .upload(let fileURL):
            return .uploadFile(fileURL)
        case .uploadMultipart(let data, let urlParameters), .validatedUploadMultipart(let data, let urlParameters, _):
            if let urlParameters = urlParameters {
                return .uploadCompositeMultipart(data, urlParameters: urlParameters)
            } else {
                return .uploadMultipart(data)
            }
        }
    }

    var sampleData: Data {
        switch self {
        case .basicAuth:
            return "{\"authenticated\": true, \"user\": \"user\"}".data(using: String.Encoding.utf8)!
        case .bearer:
            return "{\"authenticated\": true, \"token\": \"4D4A9C7D-F6E7-4FD7-BDBD-03880550A80D\"}".data(using: String.Encoding.utf8)!
        case .post, .upload, .uploadMultipart, .validatedUploadMultipart:
            return "{\"args\": {}, \"data\": \"\", \"files\": {}, \"form\": {}, \"headers\": { \"Connection\": \"close\", \"Content-Length\": \"0\", \"Host\": \"httpbin.org\" },  \"json\": null, \"origin\": \"198.168.1.1\", \"url\": \"https://httpbin.org/post\"}".data(using: String.Encoding.utf8)!
        }
    }

    var headers: [String: String]? {
        return nil
    }

    var validationType: ValidationType {
        switch self {
        case .validatedUploadMultipart(_, _, let codes):
            return .customCodes(codes)
        default:
            return .none
        }
    }

    var authorizationType: AuthorizationType {
        switch self {
        case .bearer:
            return  .bearer
        default:
            return .none
        }
    }
}

public enum GitHubUserContent {
    case downloadMoyaWebContent(String)
    case requestMoyaWebContent(String)
}

extension GitHubUserContent: TargetType {
    public var baseURL: URL { return URL(string: "https://raw.githubusercontent.com")! }
    public var path: String {
        switch self {
        case .downloadMoyaWebContent(let contentPath), .requestMoyaWebContent(let contentPath):
            return "/Moya/Moya/master/web/\(contentPath)"
        }
    }
    public var method: Moya.Method {
        switch self {
        case .downloadMoyaWebContent, .requestMoyaWebContent:
            return .get
        }
    }
    public var parameters: [String: Any]? {
        switch self {
        case .downloadMoyaWebContent, .requestMoyaWebContent:
            return nil
        }
    }
    public var parameterEncoding: ParameterEncoding {
        return URLEncoding.default
    }
    public var task: Task {
        switch self {
        case .downloadMoyaWebContent:
            return .downloadDestination(defaultDownloadDestination)
        case .requestMoyaWebContent:
            return .requestPlain
        }
    }
    public var sampleData: Data {
        switch self {
        case .downloadMoyaWebContent, .requestMoyaWebContent:
            return Data(count: 4000)
        }
    }

    public var headers: [String: String]? {
        return nil
    }
}

// MARK: - Upload Multipart Helpers

extension HTTPBin {
    static func createTestMultipartFormData() -> [MultipartFormData] {
        let url = testImageUrl
        let string = "some data"
        guard let data = string.data(using: .utf8) else {
            fatalError("Failed creating Data from String \(string)")
        }
        return [
            MultipartFormData(provider: .file(url), name: "file", fileName: "testImage"),
            MultipartFormData(provider: .data(data), name: "data")
        ]
    }
}

// MARK: - String Helpers
extension String {
    var urlEscaped: String {
        return self.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
    }
}

// MARK: - DispatchQueue Test Helpers
// https://lists.swift.org/pipermail/swift-users/Week-of-Mon-20160613/002280.html
extension DispatchQueue {
    class var currentLabel: String? {
        return String(validatingUTF8: __dispatch_queue_get_label(nil))
    }
}

private let defaultDownloadDestination: DownloadDestination = { temporaryURL, response in
    let directoryURLs = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)

    if !directoryURLs.isEmpty {
        return (directoryURLs.first!.appendingPathComponent(response.suggestedFilename!), [])
    }

    return (temporaryURL, [])
}

extension URL {
    static func random(withExtension extension: String) -> URL {
        let directory = FileManager.default.temporaryDirectory
        let name = UUID().uuidString + "." + `extension`
        return directory.appendingPathComponent(name, isDirectory: false)
    }
}

// MARK: - Image Test Helpers
// Necessary since Image(named:) doesn't work correctly in the test bundle
extension ImageType {
    class TestClass { }

    static var testImage: ImageType {
        return Image(data: testImageData)!
    }

    #if canImport(UIKit)
        func asJPEGRepresentation(_ compression: CGFloat) -> Data? {
            return jpegData(compressionQuality: compression)
        }
    #elseif canImport(AppKit)
        func asJPEGRepresentation(_ compression: CGFloat) -> Data? {
            var imageRect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
            let imageRep = NSBitmapImageRep(cgImage: self.cgImage(forProposedRect: &imageRect, context: nil, hints: nil)!)
            return imageRep.representation(using: .jpeg, properties: [:])
        }
    #endif
}

// A fixture for testing Decodable mapping
struct Issue: Codable {
    let title: String
    let createdAt: Date
    let rating: Float?

    enum CodingKeys: String, CodingKey {
        case title
        case createdAt
        case rating
    }
}

// A fixture for testing optional Decodable mapping
struct OptionalIssue: Codable {
    let title: String?
    let createdAt: Date?
}
