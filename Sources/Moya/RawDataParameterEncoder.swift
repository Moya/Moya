import Foundation
import Moya

/// An "encoder" that expects the given parameters to be of type `Data` and just sets the request's httpBody with it, without any additional encoding.
struct RawDataParameterEncoder: ParameterEncoder {
    func encode<Parameters>(_ parameters: Parameters?, into request: URLRequest) throws -> URLRequest where Parameters: Encodable {
        var request = request
        var data: Data? = parameters as? Data
        if data == nil {
            data = (parameters as? AnyEncodable)?.encodable as? Data
        }
        request.httpBody = data
        return request
    }
}
