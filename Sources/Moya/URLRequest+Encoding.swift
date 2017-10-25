import Foundation

internal extension URLRequest {

    mutating func encoded(encodable: Encodable) throws -> URLRequest {
        do {
            let encodable = AnyEncodable(encodable)
            httpBody = try JSONEncoder().encode(encodable)

            if value(forHTTPHeaderField: "Content-Type") == nil {
                setValue("application/json", forHTTPHeaderField: "Content-Type")
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
