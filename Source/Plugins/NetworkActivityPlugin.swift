import Foundation
import Result

/// Network activity change notification type.
public enum NetworkActivityChangeType {
    case Began, Ended
}

/// Notify a request's network activity changes (request begins or ends).
public final class NetworkActivityPlugin: PluginType {
    
    public typealias NetworkActivityClosure = (change: NetworkActivityChangeType) -> ()
    let networkActivityClosure: NetworkActivityClosure
    
    public init(networkActivityClosure: NetworkActivityClosure) {
        self.networkActivityClosure = networkActivityClosure
    }

    // MARK: Plugin

    /// Called by the provider as soon as the request is about to start
    public func willSendRequest(request: RequestType, target: TargetType) {
        networkActivityClosure(change: .Began)
    }
    
    /// Called by the provider as soon as a response arrives, even the request is cancelled.
    public func didReceiveResponse(result: Result<Moya.Response, Moya.Error>, target: TargetType) {
        networkActivityClosure(change: .Ended)
    }
}
