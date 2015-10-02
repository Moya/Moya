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
    
    
    // MARK: PluginType
    
    public override func willSendRequest(token: Target, request: Alamofire.Request) -> Alamofire.Request {
        networkActivityClosure(change: .Began)
        return request
    }
    
    public override func didReceiveResponse(token: Target, data: NSData?, statusCode: Int?, response: NSURLResponse?, error: ErrorType?) {
        networkActivityClosure(change: .Ended)
    }
    
    public override func willSendStubbedRequest(token: Target, request: NSURLRequest) {
        networkActivityClosure(change: .Began)
    }
    
    public override func didReceiveStubbedResponse(token: Target, data: NSData?, statusCode: Int?, response: NSURLResponse?, error: ErrorType?) {
        networkActivityClosure(change: .Ended)
    }
    
}