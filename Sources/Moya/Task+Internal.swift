import Foundation
import Moya

extension Task {
    typealias TaskParameters = (Encodable, ParameterEncoder)

    func allParameters() throws -> [TaskParameters] {

        var providers: [TaskParametersProvider?] = [bodyParams, queryParams]
        if let customProviders = customParams {
            providers.append(contentsOf: customProviders)
        }

        return try providers
            .compactMap { $0 }
            .map { try $0.taskParameters() }

    }

    var bodyParams: BodyParams? {
        switch self {
        case let .request(params, _, _),
             let .download(_, params, _, _):
            return params

        case .upload:
            return nil
        }
    }

    var queryParams: QueryParams? {
        switch self {
        case let .request(_, params, _),
             let .upload(_, params, _),
             let .download(_, _, params, _):
            return params
        }
    }

    var customParams: [CustomParams]? {
        switch self {
        case let .request(_, _, params),
             let .upload(_, _, params),
             let .download(_, _, _, params):
            return params
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
            return (encodable, URLEncodedFormParameterEncoder(encoder: encoder, destination: .httpBody))

        case let .json(encodable, encoder):
            return (encodable, JSONParameterEncoder(encoder: encoder))

        case let .raw(encodable):
            return (encodable, RawDataParameterEncoder())
        }
    }
}

extension Task.QueryParams: TaskParametersProvider {
    func taskParameters() throws -> Task.TaskParameters {
        return (encodable, URLEncodedFormParameterEncoder(encoder: encoder, destination: .queryString))
    }
}

extension Task.CustomParams: TaskParametersProvider {
    func taskParameters() throws -> Task.TaskParameters {
        if encoder is JSONParameterEncoder {
            throw MoyaError.encodableMapping("A JSONParameterEncoder can not be used in Task.BodyParams.custom(). Use Task.BodyParams.json() instead.")
        }
        if encoder is URLEncodedFormParameterEncoder {
            throw MoyaError.encodableMapping("An URLEncodedFormParameterEncoder can not be used in Task.CustomParams. Use Task.BodyParams.urlEncoded() or Task.QueryParams instead.")
        }
        return (encodable, encoder)
    }
}
