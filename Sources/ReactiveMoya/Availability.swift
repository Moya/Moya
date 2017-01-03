import Moya
import ReactiveSwift

@available(*, unavailable, renamed: "ReactiveSwiftMoyaProvider")
public class ReactiveCocoaMoyaProvider { }

extension ReactiveSwiftMoyaProvider {
    @available(*, unavailable, renamed: "request(_:)")
    public func request(token: Target) -> SignalProducer<Response, MoyaError> { fatalError() }
}
