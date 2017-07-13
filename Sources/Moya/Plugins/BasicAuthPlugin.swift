import Moya

/// Plugin for adding Basic Authorization header to requests
public struct BasicAuthenticationPlugin: PluginType {
    let key: String

    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        let encodedKey = key.utf8Encoded.base64EncodedString(options: [])
        var request = request
        request.addValue("Basic " + encodedKey, forHTTPHeaderField: "Authorization")
        return request
    }
}
