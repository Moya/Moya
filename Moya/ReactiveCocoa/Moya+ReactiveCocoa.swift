import Foundation
import ReactiveCocoa
import Alamofire

/// Subclass of MoyaProvider that returns RACSignal instances when requests are made. Much better than using completion closures.
public class ReactiveCocoaMoyaProvider<Target where Target: MoyaTarget>: MoyaProvider<Target> {

    /// Initializes a reactive provider.
    override public init(endpointClosure: EndpointClosure = MoyaProvider.DefaultEndpointMapping,
        requestClosure: RequestClosure = MoyaProvider.DefaultRequestMapping,
        stubClosure: StubClosure = MoyaProvider.NeverStub,
        networkActivityClosure: Moya.NetworkActivityClosure? = nil,
        credentialClosure: CredentialClosure? = nil,
        manager: Manager = Alamofire.Manager.sharedInstance) {
        
            super.init(endpointClosure: endpointClosure, requestClosure: requestClosure, stubClosure: stubClosure, networkActivityClosure: networkActivityClosure, credentialClosure: credentialClosure, manager: manager)
    }

    /// Designated request-making method.
    public func request(token: Target) -> RACSignal {
        
        // weak self just for best practices – RACSignal will take care of any retain cycles anyway,
        // and we're connecting immediately (below), so self in the block will always be non-nil

        return RACSignal.`defer` { [weak self] () -> RACSignal! in

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
                    cancellableToken?.cancel()
                }
            }.publish().autoconnect()

            
            return signal
        }
    }
}
