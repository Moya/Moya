import Foundation
import Moya

extension Task {
    typealias Parameters = (Encodable, ParameterEncoder)

    /// Returns the list of all pairs of encodable and encoders to use when generating the `URLRequest`.
    func allParameters() throws -> [Parameters] {

        var providers: [TaskParametersProvider?] = [bodyParams, urlParams]
        if let customProviders = customParams {
            providers.append(contentsOf: customProviders)
        }

        return try providers
            .compactMap { $0 }
            .map { try $0.parameters() }

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

// MARK: - TaskParametersProvider

private protocol TaskParametersProvider {
    func parameters() throws -> Task.Parameters
}

extension Task.BodyParams: TaskParametersProvider {
    func parameters() throws -> Task.Parameters {
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

extension Task.URLParams: TaskParametersProvider {
    func parameters() throws -> Task.Parameters {
        return (encodable, URLEncodedFormParameterEncoder(encoder: encoder, destination: .queryString))
    }
}

extension Task.CustomParams: TaskParametersProvider {
    func parameters() throws -> Task.Parameters {
        // CustomParams should only be used when `URLEncodedFormParameterEncoder` and `JSONParameterEncoder`
        // are not enough. To enforce usage of BodyParams or URLParams, let's check the type of the given encoder
        // to make sure CustomParams is correctly used.
        if encoder is JSONParameterEncoder {
            throw MoyaError.encodableMapping("A JSONParameterEncoder can not be used in Task.BodyParams.custom(). Use Task.BodyParams.json() instead.")
        }
        if encoder is URLEncodedFormParameterEncoder {
            throw MoyaError.encodableMapping("An URLEncodedFormParameterEncoder can not be used in Task.CustomParams. Use Task.BodyParams.urlEncoded() or Task.URLParams instead.")
        }
        return (encodable, encoder)
    }
}
