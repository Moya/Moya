import Foundation
import Moya

extension Task {

    /// Returns all `TaskParametersType` objects to use when generating the `URLRequest`.
    func allParameters() -> [TaskParametersType] {
        var providers: [TaskParametersType?] = [bodyParams, urlParams]
        if let customProviders = customParams {
            providers.append(contentsOf: customProviders)
        }
        return providers.compactMap { $0 }
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

    var urlParams: URLParams? {
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

// MARK: - TaskParametersType

protocol TaskParametersType {
    var encodable: Encodable {get}
    var encoder: ParameterEncoder {get}
}

extension Task.Parameters: TaskParametersType {}

extension Task.BodyParams: TaskParametersType {

    var encodable: Encodable {
        switch self {
        case let .raw(encodable as Encodable),
             let .json(encodable, _),
             let .urlEncoded(encodable, _):
            return encodable
        }
    }

    var encoder: ParameterEncoder {
        switch self {
        case .raw:
            return RawDataParameterEncoder()

        case let .json( _, encoder):
            return JSONParameterEncoder(encoder: encoder)

        case let .urlEncoded( _, encoder):
            return URLEncodedFormParameterEncoder(encoder: encoder, destination: .httpBody)
        }
    }
}
