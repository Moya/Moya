import Foundation

public let MoyaErrorDomain = "Moya"

public enum MoyaErrorCode: Int {
    case ImageMapping = 0
    case JSONMapping
    case StringMapping
    case StatusCode
    case Data
}

public enum MoyaError: ErrorType {
    case ImageMapping(MoyaResponse)
    case JSONMapping(MoyaResponse)
    case StringMapping(MoyaResponse)
    case StatusCode(Int,MoyaResponse)
    case Data(MoyaResponse)
    case Underlying(ErrorType)
}