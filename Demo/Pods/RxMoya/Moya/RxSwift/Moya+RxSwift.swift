import Foundation
import RxSwift
import Alamofire

/// Subclass of MoyaProvider that returns Observable instances when requests are made. Much better than using completion closures.
public class RxMoyaProvider<Target where Target: MoyaTarget>: MoyaProvider<Target> {
    /// Initializes a reactive provider.
    override public init(endpointClosure: EndpointClosure = MoyaProvider.DefaultEndpointMapping,
        requestClosure: RequestClosure = MoyaProvider.DefaultRequestMapping,
        stubClosure: StubClosure = MoyaProvider.NeverStub,
        manager: Manager = Alamofire.Manager.sharedInstance,
        plugins: [Plugin<Target>] = []) {
            super.init(endpointClosure: endpointClosure, requestClosure: requestClosure, stubClosure: stubClosure, manager: manager, plugins: plugins)
    }

    /// Designated request-making method.
    public func request(token: Target) -> Observable<MoyaResponse> {

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
