import Foundation

public enum MoyaError: Swift.Error {

    /// Indicates a response failed to map to an image.
    case imageMapping(Response)

    /// Indicates a response failed to map to a JSON structure.
    case jsonMapping(Response)

    /// Indicates a response failed to map to a String.
    case stringMapping(Response)

    /// Indicates a response failed with an invalid HTTP status code.
    case statusCode(Response)

    /// Indicates a response failed due to an underlying `Error`.
    case underlying(Swift.Error)

    /// Indicates that an `Endpoint` failed to map to a `URLRequest`.
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
        case .underlying: return nil
        case .requestMapping: return nil
        }
    }
}

// MARK: - Error Descriptions

extension MoyaError: LocalizedError {
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
