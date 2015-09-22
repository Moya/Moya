import Foundation
import ReactiveCocoa
import Alamofire

/// Subclass of MoyaProvider that returns SignalProducer<MoyaReponse, NSError> instances when requests are made. Much better than using completion closures.
public class ReactiveCocoaMoyaProvider<T where T: MoyaTarget>: MoyaProvider<T> {

    /// Initializes a reactive provider.
    override public init(endpointClosure: MoyaEndpointsClosure = MoyaProvider.DefaultEndpointMapping, endpointResolver: MoyaEndpointResolution = MoyaProvider.DefaultEndpointResolution, stubBehavior: MoyaStubbedBehavior = MoyaProvider.NoStubbingBehavior, credentialClosure: MoyaCredentialClosure? = nil, networkActivityClosure: Moya.NetworkActivityClosure? = nil, manager: Manager = Alamofire.Manager.sharedInstance) {
        super.init(endpointClosure: endpointClosure, endpointResolver: endpointResolver, stubBehavior: stubBehavior, credentialClosure: credentialClosure, networkActivityClosure: networkActivityClosure, manager: manager)
    }
    
    /// Designated request-making method.
    public func request(token: T) -> SignalProducer<MoyaResponse, NSError> {

        /// returns a new producer which starts a new producer which invokes the requests. The created signal of the inner producer is saved for inflight request
        return SignalProducer { [weak self] outerSink, outerDisposable in
            
            let producer: SignalProducer<MoyaResponse, NSError> = SignalProducer { [weak self] requestSink, requestDisposable in
                
                let cancellableToken = self?.request(token) { data, statusCode, response, error in
                    if let error = error {
                        if let statusCode = statusCode {
                            sendError(requestSink, NSError(domain: MoyaErrorDomain, code: statusCode, userInfo: [NSUnderlyingErrorKey: error as NSError]))
                        } else {
                            sendError(requestSink, error as NSError)
                        }
                    } else {
                        if let data = data {
                            sendNext(requestSink, MoyaResponse(statusCode: statusCode!, data: data, response: response))
                        }
                        sendCompleted(requestSink)
                    }
                }
                
                requestDisposable.addDisposable {
                    // Cancel the request
                    cancellableToken?.cancel()
                }
            }

            /// starts the inner signal producer and store the created signal.
            producer.startWithSignal { signal, innerDisposable in
                /// connect all events of the signal to the observer of this signal producer
                signal.observe(outerSink)
                outerDisposable.addDisposable(innerDisposable)
            }
        }
    }
    
    public func request(token: T) -> RACSignal {
        return toRACSignal(request(token))
    }
}
