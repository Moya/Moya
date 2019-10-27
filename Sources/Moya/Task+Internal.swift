import Foundation
import Moya

extension Task {
    typealias TaskParameters = (Encodable, ParameterEncoder)

    func allParameters() throws -> [TaskParameters] {
        switch self {
        case let .request(bodyParams, queryParams),
             let .upload(_, bodyParams, queryParams),
             let .download(_, bodyParams, queryParams):
            return try [bodyParams?.taskParameters(), queryParams?.taskParameters()].compactMap { $0 }
        }
    }
}

// MARK: - TaskParametersProvider
private protocol TaskParametersProvider {
    func taskParameters() throws -> Task.TaskParameters
}

extension Task.BodyParams: TaskParametersProvider {
    func taskParameters() throws -> Task.TaskParameters {
        switch self {
        case let .urlEncoded(encodable, encoder):
            guard encoder.destination == .httpBody else {
                throw MoyaError.encodableMapping("The encoder defined in Task.BodyParams.urlEncoded() can only use the .httpBody destination.")
            }
            return (encodable, encoder)

        case let .custom(encodable, encoder):
            guard !(encoder is JSONParameterEncoder) else {
                throw MoyaError.encodableMapping("A JSONParameterEncoder can not be used in Task.BodyParams.custom(). Use Task.BodyParams.json() instead.")
            }
            guard !(encoder is URLEncodedFormParameterEncoder) else {
                throw MoyaError.encodableMapping("An URLEncodedFormParameterEncoder can not be used in Task.BodyParams.custom(). Use Task.BodyParams.urlEncoded() instead.")
            }
            return (encodable, encoder)

        case let .json(encodable, encoder as ParameterEncoder):
            return (encodable, encoder)

        case let .raw(encodable):
            return (encodable, RawDataEncoder())
        }
    }
}

extension Task.QueryParams: TaskParametersProvider {
    func taskParameters() throws -> Task.TaskParameters {
        switch self {
        case let .query(encodable, encoder):
            guard encoder.destination == .queryString else {
                throw MoyaError.encodableMapping("The encoder defined in Task.QueryParams.query() can only use the .queryString destination.")
            }
            return (encodable, encoder)
        }
    }
}

// MARK: - RawDataEncoder

/// An "encoder" that expects the given parameters to be of type `Data` and just sets the request's httpBody with it, without any additional encoding.
struct RawDataEncoder: ParameterEncoder {
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
