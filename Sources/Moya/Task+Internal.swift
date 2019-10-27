import Foundation

private protocol TaskParametersProvider {
    var taskParameters: Task.TaskParameters {get}
}

extension Task.BodyParams: TaskParametersProvider {
    var taskParameters: Task.TaskParameters {
        switch self {
        case let .json(encodable, encoder as ParameterEncoder),
             let .urlEncoded(encodable, encoder as ParameterEncoder),
             let .custom(encodable, encoder):
            return (encodable, encoder)

        case let .raw(encodable):
            return (encodable, RawDataEncoder())
        }
    }
}

extension Task.QueryParams: TaskParametersProvider {
    var taskParameters: Task.TaskParameters {
        switch self {
        case let .query(encodable, encoder):
            return (encodable, encoder)
        }
    }
}

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
