import Foundation
import Alamofire

/// Network activity change notification type.
public enum NetworkActivityChangeType {
    case Began, Ended
}

/// Provides each request with optional NSURLCredentials.
public class NetworkActivityPlugin<Target: MoyaTarget>: Plugin<Target> {
    
    public typealias NetworkActivityClosure = (change: NetworkActivityChangeType) -> ()
    let networkActivityClosure: NetworkActivityClosure
    
    public init(networkActivityClosure: NetworkActivityClosure) {
        self.networkActivityClosure = networkActivityClosure
    }
    
    
    // MARK: Plugin
    
    /// Called by the provider as soon as the request is about to start
    public override func willSendRequest(request: Alamofire.Request, provider: MoyaProvider<Target>, target: Target) -> Alamofire.Request {
        networkActivityClosure(change: .Began)
        return request
    }

    /// Called by the provider as soon as a response arrives
    public override func didReceiveResponse(data: NSData?, statusCode: Int?, response: NSURLResponse?, error: ErrorType?, provider: MoyaProvider<Target>, target: Target) {
        networkActivityClosure(change: .Ended)
    }
    
}