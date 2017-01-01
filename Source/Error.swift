import Foundation

public enum Error: Swift.Error {
    case imageMapping(Response)
    case jsonMapping(Response)
    case stringMapping(Response)
    case statusCode(Response)
    case underlying(Swift.Error)
    case requestMapping(String)
}

public extension Moya.Error {
    /// Depending on error type, returns a `Response` object.
    var response: Moya.Response? {
        switch self {
        case .imageMapping(let response): return response
        case .jsonMapping(let response): return response
        case .stringMapping(let response): return response
        case .statusCode(let response): return response
        case .underlying: return nil
        case .requestMapping: return nil
        }
    }
}

// MARK: - Error Descriptions

extension Moya.Error: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .imageMapping:
            return "Failed to map data to an Image."
        case .jsonMapping:
            return "Failed to map data to JSON."
        case .stringMapping:
            return "Failed to map data to a String."
        case .statusCode:
            return "Status code didn't fall within the given range."
        case .requestMapping:
            return "Failed to map Endpoint to a URLRequest."
        case .underlying(let error):
            return error.localizedDescription
        }
    }
}
