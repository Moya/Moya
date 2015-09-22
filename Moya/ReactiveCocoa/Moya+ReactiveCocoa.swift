import Foundation
import ReactiveCocoa
import Alamofire

/// Subclass of MoyaProvider that returns RACSignal instances when requests are made. Much better than using completion closures.
public class ReactiveCocoaMoyaProvider<T where T: MoyaTarget>: MoyaProvider<T> {
    /// Current requests that have not completed or errored yet.
    /// Note: Do not access this directly. It is public only for unit-testing purposes (sigh).
    public var inflightRequests = Dictionary<Endpoint<T>, RACSignal>()

    /// Initializes a reactive provider.
    override public init(endpointClosure: MoyaEndpointsClosure = MoyaProvider.DefaultEndpointMapping, endpointResolver: MoyaEndpointResolution = MoyaProvider.DefaultEndpointResolution, stubBehavior: MoyaStubbedBehavior = MoyaProvider.NoStubbingBehavior, credentialClosure: MoyaCredentialClosure? = nil, networkActivityClosure: Moya.NetworkActivityClosure? = nil, manager: Manager = Alamofire.Manager.sharedInstance) {
        super.init(endpointClosure: endpointClosure, endpointResolver: endpointResolver, stubBehavior: stubBehavior, credentialClosure: credentialClosure, networkActivityClosure: networkActivityClosure, manager: manager)
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
                let cancellableToken = self?.request(token) { data, statusCode, response, error in
                    if let error = error {
                        if let statusCode = statusCode {
                            subscriber.sendError(NSError(domain: MoyaErrorDomain, code: statusCode, userInfo: [NSUnderlyingErrorKey: error as NSError]))
                        } else {
                            subscriber.sendError(error as NSError)
                        }
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
