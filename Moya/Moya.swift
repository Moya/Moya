import Foundation
import Alamofire

/// Block to be executed when a request has completed.
public typealias MoyaCompletion = (data: NSData?, statusCode: Int?, response: NSURLResponse?, error: NSError?) -> ()

/// General-purpose class to store some enums and class funcs.
public class Moya {

    /// Network activity change notification type.
    public enum NetworkActivityChangeType {
        case Began, Ended
    }

    /// Network activity change notification closure typealias.
    public typealias NetworkActivityClosure = (change: NetworkActivityChangeType) -> ()
    
    /// Represents an HTTP method.
    public enum Method {
        case GET, POST, PUT, DELETE, OPTIONS, HEAD, PATCH, TRACE, CONNECT

        func method() -> Alamofire.Method {
            switch self {
            case .GET:
                return .GET
            case .POST:
                return .POST
            case .PUT:
                return .PUT
            case .DELETE:
                return .DELETE
            case .HEAD:
                return .HEAD
            case .OPTIONS:
                return .OPTIONS
            case PATCH:
                return .PATCH
            case TRACE:
                return .TRACE
            case .CONNECT:
                return .CONNECT
            }
        }
    }

    /// Choice of parameter encoding.
    public enum ParameterEncoding {
        case URL
        case JSON
        case PropertyList(NSPropertyListFormat, NSPropertyListWriteOptions)
        case Custom((URLRequestConvertible, [String: AnyObject]?) -> (NSMutableURLRequest, NSError?))
        
        func parameterEncoding() -> Alamofire.ParameterEncoding {
            switch self {
            case .URL:
                return .URL
            case .JSON:
                return .JSON
            case .PropertyList(let format, let options):
                return .PropertyList(format, options)
            case .Custom(let closure):
                return .Custom(closure)
            }
        }
    }

    public enum StubbedBehavior {
        case NoStubbing
        case Immediate
        case Delayed(seconds: NSTimeInterval)
    }
}

/// Protocol to define the base URL, path, method, parameters and sample data for a target.
public protocol MoyaTarget {
    var baseURL: NSURL { get }
    var path: String { get }
    var method: Moya.Method { get }
    var parameters: [String: AnyObject] { get }
    var sampleData: NSData { get }
}

/// Protocol to define the opaque type returned from a request
public protocol Cancellable {
    func cancel()
}

/// Internal token that can be used to cancel requests
struct CancellableToken: Cancellable {
    let cancelAction: () -> ()
    
    func cancel() {
        cancelAction()
    }
}

/// Request provider class. Requests should be made through this class only.
public class MoyaProvider<T: MoyaTarget> {
    /// Closure that defines the endpoints for the provider.
    public typealias MoyaEndpointsClosure = (T) -> (Endpoint<T>)
    /// Closure that resolves an Endpoint into an NSURLRequest.
    public typealias MoyaEndpointResolution = (endpoint: Endpoint<T>) -> (NSURLRequest)
    public typealias MoyaStubbedBehavior = ((T) -> (Moya.StubbedBehavior))
    
    public let endpointClosure: MoyaEndpointsClosure
    public let endpointResolver: MoyaEndpointResolution
    public let stubBehavior: MoyaStubbedBehavior
    public let networkActivityClosure: Moya.NetworkActivityClosure?
    public let manager: Manager

    /// Initializes a provider.
    public init(endpointClosure: MoyaEndpointsClosure = MoyaProvider.DefaultEndpointMapping, endpointResolver: MoyaEndpointResolution = MoyaProvider.DefaultEnpointResolution, stubBehavior: MoyaStubbedBehavior = MoyaProvider.NoStubbingBehavior, networkActivityClosure: Moya.NetworkActivityClosure? = nil, manager: Manager = Alamofire.Manager.sharedInstance) {
        self.endpointClosure = endpointClosure
        self.endpointResolver = endpointResolver
        self.stubBehavior = stubBehavior
        self.networkActivityClosure = networkActivityClosure
        self.manager = manager
    }
    
    /// Returns an Endpoint based on the token, method, and parameters by invoking the endpointsClosure.
    public func endpoint(token: T) -> Endpoint<T> {
        return endpointClosure(token)
    }
    
    /// Designated request-making method.
    public func request(token: T, completion: MoyaCompletion) -> Cancellable {
        let endpoint = self.endpoint(token)
        let request = endpointResolver(endpoint: endpoint)
        let stubBehavior = self.stubBehavior(token)

        switch stubBehavior {
        case .NoStubbing:
            return sendRequest(request, completion: completion)
        default:
            return stubRequest(request, completion: completion, endpoint: endpoint, stubBehavior: stubBehavior)
        }
    }

    public class func DefaultEndpointMapping(target: T) -> Endpoint<T> {
        let url = target.baseURL.URLByAppendingPathComponent(target.path).absoluteString
        return Endpoint(URL: url!, sampleResponse: .Success(200, {target.sampleData}), method: target.method, parameters: target.parameters)
    }

    public class func DefaultEnpointResolution(endpoint: Endpoint<T>) -> NSURLRequest {
        return endpoint.urlRequest
    }

    public class func NoStubbingBehavior(_: T) -> Moya.StubbedBehavior {
        return .NoStubbing
    }

    public class func ImmediateStubbingBehaviour(_: T) -> Moya.StubbedBehavior {
        return .Immediate
    }

    public class func DelayedStubbingBehaviour(seconds: NSTimeInterval) -> MoyaStubbedBehavior {
        return { (_: T) -> Moya.StubbedBehavior in return .Delayed(seconds: seconds) }
    }
}

private extension MoyaProvider {
    func sendRequest(request: NSURLRequest, completion: MoyaCompletion) -> CancellableToken {

        networkActivityClosure?(change: .Began)

        // We need to keep a reference to the closure without a reference to ourself.
        let networkActivityCallback = networkActivityClosure
        let request = manager.request(request)
            .response { (request: NSURLRequest, response: NSHTTPURLResponse?, data: AnyObject?, error: NSError?) -> () in
                networkActivityCallback?(change: .Ended)

                // Alamofire always sends the data param as an NSData? type, but we'll
                // add a check just in case something changes in the future.
                let statusCode = response?.statusCode
                if let data = data as? NSData {
                    completion(data: data, statusCode: statusCode, response:response, error: error)
                } else {
                    completion(data: nil, statusCode: statusCode, response:response, error: error)
                }
        }

        return CancellableToken {
            request.cancel()
        }
    }

    func stubRequest(request: NSURLRequest, completion: MoyaCompletion, endpoint: Endpoint<T>, stubBehavior: Moya.StubbedBehavior) -> CancellableToken {
        var canceled = false
        let cancellableToken = CancellableToken { canceled = true }

        // Begin network activity closure
        networkActivityClosure?(change: .Began)

        let stub: () -> () = {
            self.networkActivityClosure?(change: .Ended)

            if (canceled) {
                completion(data: nil, statusCode: nil, response: nil, error: NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled, userInfo: nil))
                return
            }

            switch endpoint.sampleResponse.evaluate() {
            case .Success(let statusCode, let data):
                completion(data: data(), statusCode: statusCode, response:nil, error: nil)
            case .Error(let statusCode, let error, let data):
                completion(data: data?(), statusCode: statusCode, response:nil, error: error)
            case .Closure:
                break  // the `evaluate()` method will never actually return a .Closure
            }
        }

        switch stubBehavior {
        case .Immediate:
            stub()
        case .Delayed(let delay):
            let killTimeOffset = Int64(CDouble(delay) * CDouble(NSEC_PER_SEC))
            let killTime = dispatch_time(DISPATCH_TIME_NOW, killTimeOffset)
            dispatch_after(killTime, dispatch_get_main_queue()) {
                stub()
            }
        case .NoStubbing:
            fatalError("Method called to stub request when stubbing is disabled.")
        }

        return cancellableToken
    }
}
