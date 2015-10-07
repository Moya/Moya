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

        /// returns a new producer which starts a new producer which invokes the requests. 
        return SignalProducer { [weak self] outerSink, outerDisposable in
            
            let producer: SignalProducer<MoyaResponse, NSError> = SignalProducer { [weak self] requestSink, requestDisposable in

                let cancellableToken = self?.request(token) { data, statusCode, response, error in
                    if let error = error {
                        sendError(requestSink, error as NSError)
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
    
    public func request(token: Target) -> RACSignal {
        return toRACSignal(request(token))
    }
}
