import Foundation

public enum Path {
    case connect(endpoint: String)
    case delete(endpoint: String)
    case get(endpoint: String)
    case head(endpoint: String)
    case options(endpoint: String)
    case patch(endpoint: String)
    case post(endpoint: String)
    case put(endpoint: String)
    case trace(endpoint: String)

    public var endpoint: String {
        switch self {
        case let .connect(endpoint),
             let .delete(endpoint),
             let .get(endpoint),
             let .head(endpoint),
             let .options(endpoint),
             let .patch(endpoint),
             let .post(endpoint),
             let .put(endpoint),
             let .trace(endpoint):
            return endpoint
        }
    }

    public var method: Moya.Method {
        switch self {
        case .connect:
            return .connect
        case .delete:
            return .delete
        case .get:
            return .get
        case .head:
            return .head
        case .options:
            return .options
        case .patch:
            return .patch
        case .post:
            return .post
        case .put:
            return .put
        case .trace:
            return .trace
        }
    }
}
