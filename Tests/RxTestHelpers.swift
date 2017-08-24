import Moya
import RxSwift

extension Response {
    func asObservable() -> Observable<Response> {
        return Observable.just(self)
    }

    func asSingle() -> Single<Response> {
        return Single.just(self)
    }
}
