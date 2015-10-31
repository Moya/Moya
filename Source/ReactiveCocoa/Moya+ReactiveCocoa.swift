import Foundation
import ReactiveCocoa
import Alamofire

/// Subclass of MoyaProvider that returns SignalProducer instances when requests are made. Much better than using completion closures.
public class ReactiveCocoaMoyaProvider<Target where Target: MoyaTarget>: MoyaProvider<Target> {
    /// Initializes a reactive provider.
    override public init(endpointClosure: EndpointClosure = MoyaProvider.DefaultEndpointMapping,
        requestClosure: RequestClosure = MoyaProvider.DefaultRequestMapping,
        stubClosure: StubClosure = MoyaProvider.NeverStub,
        manager: Manager = Alamofire.Manager.sharedInstance,
        plugins: [Plugin<Target>] = []) {
            super.init(endpointClosure: endpointClosure, requestClosure: requestClosure, stubClosure: stubClosure, manager: manager, plugins: plugins)
    }
    
    /// Designated request-making method.
    public func request(token: Target) -> SignalProducer<MoyaResponse, NSError> {
        
        // Creates a producer that starts a request each time it's started.
        return SignalProducer { [weak self] observer, requestDisposable in
            let cancellableToken = self?.request(token) { data, statusCode, response, error in
                if let error = error {
                    observer.sendFailed(error as NSError)
                } else {
                    if let data = data {
                        observer.sendNext(MoyaResponse(statusCode: statusCode!, data: data, response: response))
                    }
                    observer.sendCompleted()
                }
            }
            
            requestDisposable.addDisposable {
                // Cancel the request
                cancellableToken?.cancel()
            }
        }
    }
    
    public func request(token: Target) -> RACSignal {
        return toRACSignal(request(token))
    }
}
