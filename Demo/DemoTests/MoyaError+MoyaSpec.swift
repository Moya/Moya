import Moya

extension MoyaError: Equatable { }

public func ==(lhs: MoyaError, rhs: MoyaError) -> Bool {
    
    switch lhs {
    case .ImageMapping:
        switch rhs {
        case .ImageMapping:
            return true
        default:
            return false
        }
    case .JSONMapping:
        switch rhs {
        case .JSONMapping:
            return true
        default:
            return false
        }
    case .StringMapping:
        switch rhs {
        case .StringMapping:
            return true
        default:
            return false
        }
    case .StatusCode:
        switch rhs {
        case .StatusCode:
            return true
        default:
            return false
        }
    case .Data:
        switch rhs {
        case .Data:
            return true
        default:
            return false
        }
    case .Underlying:
        switch rhs {
        case .Underlying:
            return true
        default:
            return false
        }
    }
}
