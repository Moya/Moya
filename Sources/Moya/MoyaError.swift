import Foundation

// Mark Moya.Error as unavaiable and offer a quick fix.
@available(*, unavailable, renamed: "MoyaError", message: "Moya.Error has been renamed to MoyaError in version 8.0.0")
public typealias Error = MoyaError

public enum MoyaError: Swift.Error {
    case imageMapping(Response)
    case jsonMapping(Response)
    case stringMapping(Response)
    case statusCode(Response)
    case data(Response)
    case underlying(Swift.Error)
    case requestMapping(String)
}

public extension MoyaError {
    /// Depending on error type, returns a `Response` object.
    var response: Moya.Response? {
        switch self {
        case .imageMapping(let response): return response
        case .jsonMapping(let response): return response
        case .stringMapping(let response): return response
        case .statusCode(let response): return response
        case .data(let response): return response
        case .underlying: return nil
        case .requestMapping: return nil
        }
    }
}
