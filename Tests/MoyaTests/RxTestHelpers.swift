import Moya
import RxSwift

extension Response {
    func asObservable() -> Observable<Response> { Observable.just(self) }

    func asSingle() -> Single<Response> { Single.just(self) }
}
