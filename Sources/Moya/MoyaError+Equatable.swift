import Foundation

fileprivate func == (lhs: Error, rhs: Error) -> Bool {
    guard type(of: lhs) == type(of: rhs) else { return false }
    
    let error1 = lhs as NSError
    let error2 = rhs as NSError
    
    return error1.domain == error2.domain &&
            error1.code == error2.code &&
            "\(lhs)" == "\(rhs)"
}

extension MoyaError: Equatable {
    public static func == (lhs: MoyaError, rhs: MoyaError) -> Bool {
        switch (lhs, rhs) {
        case (let .imageMapping(r), let .imageMapping(r2)):
            return r == r2
        case (let .jsonMapping(r), let .jsonMapping(r2)):
            return r == r2
        case (let .stringMapping(r), let .stringMapping(r2)):
            return r == r2
        case (let .objectMapping(e, r), let .objectMapping(e2, r2)):
            return e == e2 && r == r2
        case (let .encodableMapping(e), let .encodableMapping(e2)):
            return e == e2
        case (let .statusCode(r), let .statusCode(r2)):
            return r == r2
        case (let .underlying(e, r), let .underlying(e2, r2)):
            return e == e2 && r == r2
        case (let .requestMapping(s), let .requestMapping(s2)):
            return s == s2
        case (let .parameterEncoding(e), let .parameterEncoding(e2)):
            return e == e2
        default:
            return false
        }
    }
}
