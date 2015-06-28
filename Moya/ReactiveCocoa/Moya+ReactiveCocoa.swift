import Foundation
import ReactiveCocoa
import Result

private let SuccessStatusCodeRange = 200...299
private let SuccessRedirectCodeRange = 200...399

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
                if let weakSelf = self {
                    objc_sync_enter(weakSelf)
                    weakSelf.inflightRequests[endpoint] = nil
                    objc_sync_exit(weakSelf)
                    
                    cancellableToken?.cancel()
                }
            }
        }
    
        objc_sync_enter(self)
        inflightRequests[endpoint] = producer
        objc_sync_exit(self)
        
        return producer
    }
}

/// Extension for mapping to a certain response type
public extension ReactiveCocoaMoyaProvider {
    public func requestJSON(token: T) -> SignalProducer<AnyObject, NSError> {
        return request(token) |> mapJSON()
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
    return attemptMap { (response: MoyaResponse) in
        if range.contains(response.statusCode) {
            return Result.Success(response)
        } else {
            return Result.Failure(ReactiveMoyaError.StatusCode(response).toError())
        }
    }
}

public func filterStatusCode(code: Int) -> Signal<MoyaResponse, NSError> -> Signal<MoyaResponse, NSError> {
    return filterStatusCode(code...code)
}

public func filterSuccessfulStatusCodes() -> Signal<MoyaResponse, NSError> -> Signal<MoyaResponse, NSError> {
    return filterStatusCode(SuccessStatusCodeRange)
}

public func filterSuccessfulAndRedirectCodes() -> Signal<MoyaResponse, NSError> -> Signal<MoyaResponse, NSError> {
    return filterStatusCode(SuccessRedirectCodeRange)
}

/// Maps the `MoyaResponse` to a `UIImage`
public func mapImage() -> Signal<MoyaResponse, NSError> -> Signal<UIImage, NSError> {
    return attemptMap { (response: MoyaResponse) -> Result<UIImage, NSError> in
        if let image = UIImage(data: response.data) {
            return Result.Success(image)
        } else {
            return Result.Failure(ReactiveMoyaError.ImageMapping(response).toError())
        }
    }
}

/// Maps the `MoyaResponse` to JSON
public func mapJSON() -> Signal<MoyaResponse, NSError> -> Signal<AnyObject, NSError> {
    return attemptMap { (response: MoyaResponse) -> Result<AnyObject, NSError> in
        do {
            let json: AnyObject = try NSJSONSerialization.JSONObjectWithData(response.data, options: NSJSONReadingOptions.AllowFragments)
            return Result.Success(json)
        } catch {
            return Result.Failure(ReactiveMoyaError.JSONMapping(response).toError())
        }
    }
}

/// Maps the `MoyaResponse` to a String
public func mapString() -> Signal<MoyaResponse, NSError> -> Signal<String, NSError> {
    return attemptMap { (response: MoyaResponse) -> Result<String, NSError> in
        if let string: String =  NSString(data: response.data, encoding: NSUTF8StringEncoding) as? String {
            return Result.Success(string)
        } else {
            return Result.Failure(ReactiveMoyaError.StringMapping(response).toError())
        }
    }
}
