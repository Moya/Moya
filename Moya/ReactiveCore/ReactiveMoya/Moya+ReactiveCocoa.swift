import Foundation
import Moya
import ReactiveCocoa
import Result

/// Subclass of MoyaProvider that returns RACSignal instances when requests are made. Much better than using completion closures.
public class ReactiveCocoaMoyaProvider<T where T: MoyaTarget>: MoyaProvider<T> {
    /// Current requests that have not completed or errored yet.
    /// Note: Do not access this directly. It is public only for unit-testing purposes (sigh).
    public var inflightRequests = Dictionary<Endpoint<T>, SignalProducer<MoyaResponse, NSError>>()

    /// Initializes a reactive provider.
    override public init(endpointClosure: MoyaEndpointsClosure = MoyaProvider.DefaultEndpointMapping, endpointResolver: MoyaEndpointResolution = MoyaProvider.DefaultEnpointResolution, stubBehavior: MoyaStubbedBehavior = MoyaProvider.NoStubbingBehavior, networkActivityClosure: Moya.NetworkActivityClosure? = nil) {
        super.init(endpointClosure: endpointClosure, endpointResolver: endpointResolver, stubBehavior: stubBehavior, networkActivityClosure: networkActivityClosure)
    }
    
    public func request(token: T) -> SignalProducer<MoyaResponse, NSError> {
        let endpoint = self.endpoint(token)
        
        if let existingSignal = inflightRequests[endpoint] {
            return existingSignal
        }
        
        let producer: SignalProducer<MoyaResponse, NSError> = SignalProducer { [weak self] sink, disposable in
            let cancellableToken = self?.request(token) { data, statusCode, response, error in
                if let error = error {
                    if let statusCode = statusCode {
                        sendError(sink, NSError(domain: error.domain, code: statusCode, userInfo: error.userInfo))
                    } else {
                        sendError(sink, error)
                    }
                } else {
                    if let data = data {
                        sendNext(sink, MoyaResponse(statusCode: statusCode!, data: data, response: response))
                    }
                    
                    sendCompleted(sink)
                }
            }
            
            disposable.addDisposable {
                println("\n\nInvoking the disposable!\n\n")
                if let weakSelf = self {
                    objc_sync_enter(weakSelf)
                    // Clear the inflight request
                    weakSelf.inflightRequests[endpoint] = nil
                    objc_sync_exit(weakSelf)
                    
                    // Cancel the request
                    cancellableToken?.cancel()
                }
            }
        }
    
        objc_sync_enter(self)
        inflightRequests[endpoint] = producer
        objc_sync_exit(self)
        
        return producer
    }
    
    public func request(token: T) -> RACSignal {
        return toRACSignal(self.request(token))
    }
}

/// Extension for mapping to a certain response type
public extension ReactiveCocoaMoyaProvider {
    public func requestJSON(token: T) -> SignalProducer<AnyObject, NSError> {
        return request(token) |> mapJSON()
    }
    
    public func requestJSONArray(token: T) -> SignalProducer<NSArray, NSError> {
        return requestJSON(token) |> mapJSONArray()
    }
    
    public func requestJSONDictionary(token: T) -> SignalProducer<NSDictionary, NSError> {
        return requestJSON(token) |> mapJSONDictionary()
    }
    
    public func requestImage(token: T) -> SignalProducer<UIImage, NSError> {
        return request(token) |> mapImage()
    }

    public func requestString(token: T) -> SignalProducer<String, NSError> {
        return request(token) |> mapString()
    }
}

/// MoyaResponse free functions

public func filterStatusCode(range: ClosedInterval<Int>) -> Signal<MoyaResponse, NSError> -> Signal<MoyaResponse, NSError>  {
    return tryMap { (response: MoyaResponse) in
        if range.contains(response.statusCode) {
            return Result.success(response)
        } else {
            return Result.failure(ReactiveMoyaError.StatusCode(response).toError())
        }
    }
}

public func filterStatusCode(code: Int) -> Signal<MoyaResponse, NSError> -> Signal<MoyaResponse, NSError> {
    return filterStatusCode(code...code)
}

public func filterSuccessfulStatusCodes() -> Signal<MoyaResponse, NSError> -> Signal<MoyaResponse, NSError> {
    return filterStatusCode(200...299)
}

public func filterSuccessfulAndRedirectCodes() -> Signal<MoyaResponse, NSError> -> Signal<MoyaResponse, NSError> {
    return filterStatusCode(200...399)
}

/// Maps the `MoyaResponse` to a `UIImage`
public func mapImage() -> Signal<MoyaResponse, NSError> -> Signal<UIImage, NSError> {
    return tryMap { (response: MoyaResponse) -> Result<UIImage, NSError> in
        if let image = UIImage(data: response.data) {
            return Result.success(image)
        } else {
            return Result.failure(ReactiveMoyaError.ImageMapping(response).toError())
        }
    }
}

/// Maps the `MoyaResponse` to JSON
public func mapJSON() -> Signal<MoyaResponse, NSError> -> Signal<AnyObject, NSError> {
    return tryMap { (response: MoyaResponse) -> Result<AnyObject, NSError> in
        var error: NSError?
        if let json: AnyObject = NSJSONSerialization.JSONObjectWithData(response.data, options: .AllowFragments, error: &error) {
            return Result.success(json)
        } else {
            return Result.failure(ReactiveMoyaError.JSONMapping(response).toError())
        }
    }
}

public func mapJSONArray() -> Signal<AnyObject, NSError> -> Signal<NSArray, NSError> {
    return tryMap { (json: AnyObject) in
        if let json = json as? NSArray {
            return Result.success(json)
        } else {
            return Result.failure(ReactiveMoyaError.JSONMapping(json).toError())
        }
    }
}

public func mapJSONDictionary() -> Signal<AnyObject, NSError> -> Signal<NSDictionary, NSError> {
    return tryMap { (json: AnyObject) in
        if let json = json as? NSDictionary {
            return Result.success(json)
        } else {
            return Result.failure(ReactiveMoyaError.JSONMapping(json).toError())
        }
    }
}

/// Maps the `MoyaResponse` to a String
public func mapString() -> Signal<MoyaResponse, NSError> -> Signal<String, NSError> {
    return tryMap { (response: MoyaResponse) -> Result<String, NSError> in
        if let string: String =  NSString(data: response.data, encoding: NSUTF8StringEncoding) as? String {
            return Result.success(string)
        } else {
            return Result.failure(ReactiveMoyaError.StringMapping(response).toError())
        }
    }
}
