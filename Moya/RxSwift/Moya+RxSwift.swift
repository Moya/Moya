import Foundation
import RxSwift
import Alamofire

/// Subclass of MoyaProvider that returns Observable instances when requests are made. Much better than using completion closures.
public class RxMoyaProvider<T where T: MoyaTarget>: MoyaProvider<T> {

    /// Initializes a reactive provider.
    override public init(endpointClosure: MoyaEndpointsClosure = MoyaProvider.DefaultEndpointMapping, endpointResolver: MoyaEndpointResolution = MoyaProvider.DefaultEndpointResolution, stubBehavior: MoyaStubbedBehavior = MoyaProvider.NoStubbingBehavior, networkActivityClosure: Moya.NetworkActivityClosure? = nil, manager: Manager = Alamofire.Manager.sharedInstance) {
        super.init(endpointClosure: endpointClosure, endpointResolver: endpointResolver, stubBehavior: stubBehavior, networkActivityClosure: networkActivityClosure, manager: manager)
    }

    /// Designated request-making method.
    public func request(token: T) -> Observable<MoyaResponse> {

        return deferred { [weak self] () -> Observable<MoyaResponse> in

            let observable: Observable<MoyaResponse> =  AnonymousObservable { observer in
                let cancellableToken = self?.request(token) { (data, statusCode, response, error) -> () in
                    if let error = error {
                        observer.on(.Error(error as NSError))
                    } else {
                        if let data = data {
                            observer.on(.Next(MoyaResponse(statusCode: statusCode!, data: data, response: response)))
                        }
                        observer.on(.Completed)
                    }                    
                }

                return AnonymousDisposable {
                    cancellableToken?.cancel()
                }
            }

            return observable
        }
    }
}
