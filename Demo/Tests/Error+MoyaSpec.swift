import Nimble
import Moya

public func beOfSameErrorType(expectedValue: Error) -> MatcherFunc<Error> {
    return MatcherFunc { actualExpression, failureMessage in
        do {
            guard let actualValue = try actualExpression.evaluate() else {
                return false
            }
            
            switch actualValue {
            case .ImageMapping:
                switch expectedValue {
                case .ImageMapping:
                    return true
                default:
                    return false
                }
            case .JSONMapping:
                switch expectedValue {
                case .JSONMapping:
                    return true
                default:
                    return false
                }
            case .StringMapping:
                switch expectedValue {
                case .StringMapping:
                    return true
                default:
                    return false
                }
            case .StatusCode:
                switch expectedValue {
                case .StatusCode:
                    return true
                default:
                    return false
                }
            case .Data:
                switch expectedValue {
                case .Data:
                    return true
                default:
                    return false
                }
            case .Underlying:
                switch expectedValue {
                case .Underlying:
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
