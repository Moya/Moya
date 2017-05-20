import Foundation
import Result

/// Network activity change notification type.
public enum NetworkActivityChangeType {
    case began, ended
}

/// Notify a request's network activity changes (request begins or ends).
public final class NetworkActivityPlugin: PluginType {

    public typealias NetworkActivityClosure = (_ change: NetworkActivityChangeType) -> Void
    let networkActivityClosure: NetworkActivityClosure

    public init(networkActivityClosure: @escaping NetworkActivityClosure) {
        self.networkActivityClosure = networkActivityClosure
    }

    // MARK: Plugin

    /// Called by the provider as soon as the request is about to start
    public func willSend(_ request: RequestType, target: TargetType) {
        networkActivityClosure(.began)
    }

    /// Called by the provider as soon as a response arrives, even if the request is cancelled.
    public func didReceive(_ result: Result<Moya.Response, MoyaError>, target: TargetType) {
        networkActivityClosure(.ended)
    }
}
