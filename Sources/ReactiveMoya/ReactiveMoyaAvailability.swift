#if !COCOAPODS
    import Moya
#endif
import ReactiveSwift

@available(*, unavailable, renamed: "ReactiveSwiftMoyaProvider", message: "ReactiveCocoaMoyaProvider has been renamed to ReactiveSwiftMoyaProvider in version 8.0.0")
public class ReactiveCocoaMoyaProvider { }

extension ReactiveSwiftMoyaProvider {
    @available(*, unavailable, renamed: "request(_:)")
    public func request(token: Target) -> SignalProducer<Response, MoyaError> { fatalError() }
}
