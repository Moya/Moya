import Foundation
import RxSwift
import Alamofire

/// Subclass of MoyaProvider that returns Observable instances when requests are made. Much better than using completion closures.
public class RxMoyaProvider<T where T: MoyaTarget>: MoyaProvider<T> {
    /// Current requests that have not completed or errored yet.
    /// Note: Do not access this directly. It is public only for unit-testing purposes (sigh).
    public var inflightRequests = Dictionary<Endpoint<T>, Observable<MoyaResponse>>()

    /// Initializes a reactive provider.
    override public init(endpointClosure: MoyaEndpointsClosure = MoyaProvider.DefaultEndpointMapping, endpointResolver: MoyaEndpointResolution = MoyaProvider.DefaultEndpointResolution, stubBehavior: MoyaStubbedBehavior = MoyaProvider.NoStubbingBehavior, credentialClosure: MoyaCredentialClosure? = nil, networkActivityClosure: Moya.NetworkActivityClosure? = nil, manager: Manager = Alamofire.Manager.sharedInstance) {
        super.init(endpointClosure: endpointClosure, endpointResolver: endpointResolver, stubBehavior: stubBehavior, networkActivityClosure: networkActivityClosure, manager: manager)
    }

    /// Designated request-making method.
    public func request(token: T) -> Observable<MoyaResponse> {
        let endpoint = self.endpoint(token)

        return defer {  [weak self] () -> Observable<MoyaResponse> in
            if let weakSelf = self {
                objc_sync_enter(weakSelf)
                let inFlight = weakSelf.inflightRequests[endpoint]
                objc_sync_exit(weakSelf)
                if let existingObservable = inFlight {
                    return existingObservable
                }
            }

            let observable: Observable<MoyaResponse> = create { observer in
                let cancellableToken = self?.request(token) { (data, statusCode, response, error) -> () in
                    if let error = error {
                        if let statusCode = statusCode {
                            sendError(observer, NSError(domain: error.domain, code: statusCode, userInfo: error.userInfo))
                        } else {
                            sendError(observer, error)
                        }
                    } else {
                        if let data = data {
                            sendNext(observer, MoyaResponse(statusCode: statusCode!, data: data, response: response))
                        }
                        sendCompleted(observer)
                    }
                }

                return AnonymousDisposable {
                    if let weakSelf = self {
                        objc_sync_enter(weakSelf)
                        weakSelf.inflightRequests[endpoint] = nil
                        cancellableToken?.cancel()
                        objc_sync_exit(weakSelf)
                    }
                }
            } >- variable

            if let weakSelf = self {
                objc_sync_enter(weakSelf)
                weakSelf.inflightRequests[endpoint] = observable
                objc_sync_exit(weakSelf)
            }

            return observable
        }
    }
}
