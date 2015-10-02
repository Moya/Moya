import Foundation
import Alamofire

/// A Moya Plugin receives callbacks to perform side effects wherever a request is sent or received.
///
/// for example, a plugin may be used to
///     - log network requests
///     - hide and show a network avtivity indicator 
///     - inject additional information into a request
public class Plugin<Target: MoyaTarget> {
    
    // NOTE:
    //
    // We cannot implement `Plugin` as a generic protocol here, because `MoyaProvider` needs
    // to keep references to an array of plugins and a generic protocol cannot be used as an array constraint.
    //
    // i.e.
    // protocol Plugin {
    //      typealias T: MoyaTarget
    //      ...
    // }
    //
    // let plugins = [Plugin]()
    // 
    // This does not work, because `plugins` is now unable to infer the actual type of the typealias `T`.
    
    func willSendRequest(token: Target, request: Alamofire.Request) -> Alamofire.Request {
        // Should be overridden if necessary
        return request
    }
    
    func didReceiveResponse(token: Target, data: NSData?, statusCode: Int?, response: NSURLResponse?, error: ErrorType?) {
        // Should be overridden if necessary
    }
    
    func willSendStubbedRequest(token: Target, request: NSURLRequest) {
        // Should be overridden if necessary
    }
    
    func didReceiveStubbedResponse(token: Target, data: NSData?, statusCode: Int?, response: NSURLResponse?, error: ErrorType?) {
        // Should be overridden if necessary
    }

}
