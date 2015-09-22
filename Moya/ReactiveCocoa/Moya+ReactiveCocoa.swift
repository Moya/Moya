import Foundation
import ReactiveCocoa
import Alamofire

/// Subclass of MoyaProvider that returns SignalProducer<MoyaReponse, NSError> instances when requests are made. Much better than using completion closures.
public class ReactiveCocoaMoyaProvider<T where T: MoyaTarget>: MoyaProvider<T> {
    /// Current requests that have not completed or errored yet.
    /// Note: Do not access this directly. It is public only for unit-testing purposes (sigh).
    public var inflightRequests = Dictionary<Endpoint<T>, Signal<MoyaResponse, NSError>>()
    
    /// Initializes a reactive provider.
    override public init(endpointClosure: MoyaEndpointsClosure = MoyaProvider.DefaultEndpointMapping, endpointResolver: MoyaEndpointResolution = MoyaProvider.DefaultEndpointResolution, stubBehavior: MoyaStubbedBehavior = MoyaProvider.NoStubbingBehavior, credentialClosure: MoyaCredentialClosure? = nil, networkActivityClosure: Moya.NetworkActivityClosure? = nil, manager: Manager = Alamofire.Manager.sharedInstance) {
        super.init(endpointClosure: endpointClosure, endpointResolver: endpointResolver, stubBehavior: stubBehavior, credentialClosure: credentialClosure, networkActivityClosure: networkActivityClosure, manager: manager)
    }
    
    /// Designated request-making method.
    public func request(token: T) -> SignalProducer<MoyaResponse, NSError> {
        let endpoint = self.endpoint(token)
        
        if let existingSignal = inflightRequests[endpoint] {
            /// returns a new producer which forwards all events of the already existing request signal
            return SignalProducer { sink, disposable in
                /// connect all events of the existing signal to the observer of this signal producer
                existingSignal.observe(sink)
            }
        } else {
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
                        if let weakSelf = self {
                            objc_sync_enter(weakSelf)
                            // Clear the inflight request
                            weakSelf.inflightRequests[endpoint] = nil
                            objc_sync_exit(weakSelf)
                            // Cancel the request
                            cancellableToken?.cancel()
                        }
                    }
                }
                
                /// starts the inner signal producer and store the created signal.
                producer.startWithSignal { [weak self] signal, innerDisposable in
                    if let weakSelf = self {
                        objc_sync_enter(weakSelf)
                        weakSelf.inflightRequests[endpoint] = signal
                        objc_sync_exit(weakSelf)
                        /// connect all events of the signal to the observer of this signal producer
                        signal.observe(outerSink)
                        outerDisposable.addDisposable(innerDisposable)
                    }
                }
            }
        }
    }
    
    public func request(token: T) -> RACSignal {
        return toRACSignal(request(token))
    }
}
