import Foundation
import ReactiveCocoa

/// Subclass of MoyaProvider that returns RACSignal instances when requests are made. Much better than using completion closures.
public class ReactiveCocoaMoyaProvider<T where T: MoyaTarget>: MoyaProvider<T> {
    /// Current requests that have not completed or errored yet.
    /// Note: Do not access this directly. It is public only for unit-testing purposes (sigh).
    public var inflightRequests = Dictionary<Endpoint<T>, RACSignal>()

    /// Initializes a reactive provider.
    override public init(endpointClosure: MoyaEndpointsClosure = MoyaProvider.DefaultEndpointMapping, endpointResolver: MoyaEndpointResolution = MoyaProvider.DefaultEnpointResolution, stubBehavior: MoyaStubbedBehavior = MoyaProvider.NoStubbingBehavior, networkActivityClosure: Moya.NetworkActivityClosure? = nil) {
        super.init(endpointClosure: endpointClosure, endpointResolver: endpointResolver, stubBehavior: stubBehavior, networkActivityClosure: networkActivityClosure)
    }

    /// Designated request-making method.
    public func request(token: T) -> RACSignal {
        let endpoint = self.endpoint(token)
        
        // weak self just for best practices – RACSignal will take care of any retain cycles anyway,
        // and we're connecting immediately (below), so self in the block will always be non-nil

        return RACSignal.`defer` { [weak self] () -> RACSignal! in
            
            if let weakSelf = self {
                objc_sync_enter(weakSelf)
                let inFlight = weakSelf.inflightRequests[endpoint]
                objc_sync_exit(weakSelf)
                if let existingSignal = inFlight {
                    return existingSignal
                }
            }
            
            let signal = RACSignal.createSignal { (subscriber) -> RACDisposable! in
                let cancellableToken = self?.request(token) { (data, statusCode, response, error) -> () in
                    if let error = error as? NSError where statusCode = statusCode {
                        // if we received an NSError, let's use its domain and userInfo and replace
                        // the status code.
                        subscriber.sendError(NSError(domain: error.domain, code: statusCode, userInfo: error.userInfo))
                    } else if let error = error {
                        // the error is not an NSError but a more generic ErrorType.
                        subscriber.sendError(error)
                    } else {
                        if let data = data {
                            subscriber.sendNext(MoyaResponse(statusCode: statusCode!, data: data, response: response))
                        }
                        subscriber.sendCompleted()
                    }
                }
                
                return RACDisposable { () -> Void in
                    if let weakSelf = self {
                        objc_sync_enter(weakSelf)
                        weakSelf.inflightRequests[endpoint] = nil
                        cancellableToken?.cancel()
                        objc_sync_exit(weakSelf)
                    }
                }
            }.publish().autoconnect()
            
            if let weakSelf = self {
                objc_sync_enter(weakSelf)
                weakSelf.inflightRequests[endpoint] = signal
                objc_sync_exit(weakSelf)
            }
            
            return signal
        }
    }
}
