import Foundation
import RxSwift
import Alamofire

/// Subclass of NetworkResourceProvider that returns Observable instances when requests are made. Much better than using completion closures.
public class RxNetworkResourceProvider<Target where Target: TargetType>: NetworkResourceProvider<Target> {
    /// Initializes a reactive provider.
    override public init(endpointClosure: EndpointClosure = NetworkResourceProvider.DefaultEndpointMapping,
        requestClosure: RequestClosure = NetworkResourceProvider.DefaultRequestMapping,
        stubClosure: StubClosure = NetworkResourceProvider.NeverStub,
        manager: Manager = Alamofire.Manager.sharedInstance,
        plugins: [Plugin] = []) {
            super.init(endpointClosure: endpointClosure, requestClosure: requestClosure, stubClosure: stubClosure, manager: manager, plugins: plugins)
    }

    /// Designated request-making method.
    public func request(token: Target) -> Observable<Response> {

        // Creates an observable that starts a request each time it's subscribed to.
        return create { [weak self] observer in
            let cancellableToken = self?.request(token) { response, error in
                if let error = error {
                    observer.onError(MoyaError.Underlying(error))
                } else if let response = response {
                    observer.onNext(response)
                    observer.onCompleted()
                }
            }

            return AnonymousDisposable {
                cancellableToken?.cancel()
            }
        }
    }
}
