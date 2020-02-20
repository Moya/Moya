import Foundation

/// An "encoder" that expects the given parameters to be of type `Data` and just sets the request's httpBody with it, without any additional encoding.
struct RawDataParameterEncoder: ParameterEncoder {
    func encode<Parameters>(_ parameters: Parameters?, into request: URLRequest) throws -> URLRequest where Parameters: Encodable {
        guard let parameters = parameters else { return request }

        var request = request

        // Avoid setting the httpBody when not needed because it has some side effects on other request's properties.
        if let data = parameters as? Data {
            request.httpBody = data
        } else if let anyEncodable = parameters as? AnyEncodable,
            let data = anyEncodable.underlyingEncodable as? Data {
            request.httpBody = data
        }

        return request
    }
}
