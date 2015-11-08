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
    
    public func sameErrorType(otherError: MoyaError) -> Bool {
        switch self {
        case .ImageMapping:
            switch otherError {
            case .ImageMapping:
                return true
            default:
                return false
            }
        case .JSONMapping:
            switch otherError {
            case .JSONMapping:
                return true
            default:
                return false
            }
        case .StringMapping:
            switch otherError {
            case .StringMapping:
                return true
            default:
                return false
            }
        case .StatusCode:
            switch otherError {
            case .StatusCode:
                return true
            default:
                return false
            }
        case .Data:
            switch otherError {
            case .Data:
                return true
            default:
                return false
            }
        case .Underlying:
            switch otherError {
            case .Underlying:
                return true
            default:
                return false
            }
        }
    }
}