import Nimble
import Moya

public func beOfSameErrorType(_ expectedValue: MoyaError) -> MatcherFunc<MoyaError> {
    return MatcherFunc { actualExpression, failureMessage in
        do {
            guard let actualValue = try actualExpression.evaluate() else {
                return false
            }
            
            switch actualValue {
            case .imageMapping:
                switch expectedValue {
                case .imageMapping:
                    return true
                default:
                    return false
                }
            case .jsonMapping:
                switch expectedValue {
                case .jsonMapping:
                    return true
                default:
                    return false
                }
            case .stringMapping:
                switch expectedValue {
                case .stringMapping:
                    return true
                default:
                    return false
                }
            case .statusCode:
                switch expectedValue {
                case .statusCode:
                    return true
                default:
                    return false
                }
            case .underlying:
                switch expectedValue {
                case .underlying:
                    return true
                default:
                    return false
                }
            case .requestMapping:
                switch expectedValue {
                case .requestMapping:
                    return true
                default:
                    return false
                }
            }
        } catch {
            return false;
        }
    }
}
