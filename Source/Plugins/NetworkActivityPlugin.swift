import Foundation
import Result

/// Network activity change notification type.
public enum NetworkActivityChangeType {
    case Began, Ended
}

/// Provides each request with optional NSURLCredentials.
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
    
    /// Called by the provider as soon as a response arrives
    public func didReceiveResponse(result: Result<Moya.Response, Moya.Error>, target: TargetType) {
        networkActivityClosure(change: .Ended)
    }
}
