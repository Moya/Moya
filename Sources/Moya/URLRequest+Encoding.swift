import Foundation

internal extension URLRequest {

    mutating func encoded(encodable: Encodable) throws -> URLRequest {
        do {
            let encodable = AnyEncodable(encodable)
            httpBody = try JSONEncoder().encode(encodable)

            let contentTypeHeaderName = "Content-Type"
            if value(forHTTPHeaderField: contentTypeHeaderName) == nil {
                setValue("application/json", forHTTPHeaderField: contentTypeHeaderName)
            }

            return self
        } catch {
            throw MoyaError.encodableMapping(error)
        }
    }

    func encoded(parameters: [String: Any], parameterEncoding: ParameterEncoding) throws -> URLRequest {
        do {
            return try parameterEncoding.encode(self, with: parameters)
        } catch {
            throw MoyaError.parameterEncoding(error)
        }
    }
}
