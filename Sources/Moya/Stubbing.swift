import Foundation

public protocol StubbedTargetType: TargetType {
    /// Provides stub data for use in testing.
    var sampleData: Data? { get }
}

/// Controls how stub responses are returned.
public enum StubBehavior {

    /// Return a response immediately.
    case immediate(ResponseType)

    /// Return a response after a delay.
    case delayed(ResponseType, seconds: TimeInterval)
}

public extension StubBehavior {
  enum ResponseType {
    /// The network returned a response, including status code and data.
    case networkResponse(Int, Data)

    /// The network returned response which can be fully customized.
    case response(HTTPURLResponse, Data)

    /// The network failed to send the request, or failed to retrieve a response (eg a timeout).
    case networkError(NSError)
    }
}

// MARK: - Utils

public extension StubBehavior {
    var responseType: ResponseType {
        switch self {
        case let .immediate(response),
             let .delayed(response, _):
            return response
        }
    }
}
