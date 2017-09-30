import Foundation
import Moya
import Result

protocol TestResultType {
    associatedtype T
    static func parse(_ object: Any) -> Self?
}

protocol DecodableTargetType: Moya.TargetType {
    associatedtype ResultType: TestResultType
}

final class MultiMoyaProvider: MoyaProvider<MultiTarget> {
    
    typealias Target = MultiTarget
    
    override init(endpointClosure: @escaping EndpointClosure = MoyaProvider.defaultEndpointMapping,
                  requestClosure: @escaping RequestClosure = MoyaProvider.defaultRequestMapping,
                  stubClosure: @escaping StubClosure = MoyaProvider.neverStub,
                  callbackQueue: DispatchQueue? = nil,
                  manager: Manager = MoyaProvider<Target>.defaultAlamofireManager(),
                  plugins: [PluginType] = [],
                  trackInflights: Bool = false) {
        
        super.init(endpointClosure: endpointClosure,
                   requestClosure: requestClosure,
                   stubClosure: stubClosure,
                   callbackQueue: callbackQueue,
                   manager: manager,
                   plugins: plugins,
                   trackInflights: trackInflights)
    }
    
    func requestDecoded<T: DecodableTargetType>(_ target: T, completion: @escaping (_ result: Result<T.ResultType, Moya.MoyaError>) -> ()) -> Cancellable {
        return request(MultiTarget(target)) { result in
            switch result {
            case .success(let response):
                guard let responseJSON = try? response.mapJSON() else {
                    completion(.failure(.jsonMapping(response)))
                    break
                }
                if let parsed = T.ResultType.parse(responseJSON) {
                    completion(.success(parsed))
                } else {
                    completion(.failure(.jsonMapping(response)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
