#if !COCOAPODS
    import Moya
#endif
import RxSwift

/// Subclass of MoyaProvider that returns Observable instances when requests are made. Much better than using completion closures.
@available(*, deprecated: 9.0.0, message: "Please use MoyaProvider with rx property: provider.rx.request(_:).")
open class RxMoyaProvider<Target>: MoyaProvider<Target> where Target: TargetType {
    /// Initializes a reactive provider.
    override public init(endpointClosure: @escaping EndpointClosure = MoyaProvider.defaultEndpointMapping,
                         requestClosure: @escaping RequestClosure = MoyaProvider.defaultRequestMapping,
                         stubClosure: @escaping StubClosure = MoyaProvider.neverStub,
                         callbackQueue: DispatchQueue? = nil,
                         manager: Manager = RxMoyaProvider<Target>.defaultAlamofireManager(),
                         plugins: [PluginType] = [],
                         trackInflights: Bool = false) {
        super.init(endpointClosure: endpointClosure, requestClosure: requestClosure, stubClosure: stubClosure, callbackQueue: callbackQueue, manager: manager, plugins: plugins, trackInflights: trackInflights)
    }

    /// Designated request-making method.
    open func request(_ token: Target, callbackQueue: DispatchQueue? = nil) -> Single<Response> {
        return rxRequest(token, callbackQueue: callbackQueue)
    }

    /// Designated request-making method with progress.
    open func requestWithProgress(_ token: Target, callbackQueue: DispatchQueue? = nil) -> Observable<ProgressResponse> {
        return rxRequestWithProgress(token, callbackQueue: callbackQueue)
    }
}
