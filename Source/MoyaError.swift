import Foundation

public enum MoyaError: ErrorType {
    case ImageMapping(Response)
    case JSONMapping(Response)
    case StringMapping(Response)
    case StatusCode(Response)
    case Data(Response)
    case Underlying(ErrorType)
}

@available(*, deprecated, message="This will be removed when ReactiveCocoa 4 becomes final. Please visit https://github.com/Moya/Moya/issues/298 for more information.")
public let MoyaErrorDomain = "Moya"

@available(*, deprecated, message="This will be removed when ReactiveCocoa 4 becomes final. Please visit https://github.com/Moya/Moya/issues/298 for more information.")
public enum MoyaErrorCode: Int {
    case ImageMapping = 0
    case JSONMapping
    case StringMapping
    case StatusCode
    case Data
}

@available(*, deprecated, message="This will be removed when ReactiveCocoa 4 becomes final. Please visit https://github.com/Moya/Moya/issues/298 for more information.")
public extension MoyaError {
    
    // Used to convert MoyaError to NSError for RACSignal
    var nsError: NSError {
        switch self {
        case .ImageMapping(let response):
            return NSError(domain: MoyaErrorDomain, code: MoyaErrorCode.ImageMapping.rawValue, userInfo: ["data" : response])
        case .JSONMapping(let response):
            return NSError(domain: MoyaErrorDomain, code: MoyaErrorCode.JSONMapping.rawValue, userInfo: ["data" : response])
        case .StringMapping(let response):
            return NSError(domain: MoyaErrorDomain, code: MoyaErrorCode.StringMapping.rawValue, userInfo: ["data" : response])
        case .StatusCode(let response):
            return NSError(domain: MoyaErrorDomain, code: MoyaErrorCode.StatusCode.rawValue, userInfo: ["data" : response])
        case .Data(let response):
            return NSError(domain: MoyaErrorDomain, code: MoyaErrorCode.Data.rawValue, userInfo: ["data" : response])
        case .Underlying(let error):
            return error as NSError
        }
    }
}
