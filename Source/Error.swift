import Foundation

public enum Error: ErrorType {
    case ImageMapping(Response)
    case JSONMapping(Response)
    case StringMapping(Response)
    case StatusCode(Response)
    case Data(Response)
    case Underlying(NSError)
}

public extension Moya.Error {
    /// Depending on error type, returns a Response object.
    var response: Moya.Response? {
        switch self {
        case .ImageMapping(let response): return response
        case .JSONMapping(let response): return response
        case .StringMapping(let response): return response
        case .StatusCode(let response): return response
        case .Data(let response): return response
        case .Underlying: return nil
        }
    }
}
