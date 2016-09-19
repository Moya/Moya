import Foundation

public enum Error: Swift.Error {
    case imageMapping(Response)
    case jsonMapping(Response)
    case stringMapping(Response)
    case statusCode(Response)
    case data(Response)
    case underlying(Swift.Error)
}

public extension Moya.Error {
    /// Depending on error type, returns a `Response` object.
    var response: Moya.Response? {
        switch self {
        case .imageMapping(let response): return response
        case .jsonMapping(let response): return response
        case .stringMapping(let response): return response
        case .statusCode(let response): return response
        case .data(let response): return response
        case .underlying: return nil
        }
    }
}
