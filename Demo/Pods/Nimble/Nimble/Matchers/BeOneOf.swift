import Foundation
import Nimble

public func beOneOf<T: Equatable>(allowedValues: [T]) -> MatcherFunc<T> {
    return MatcherFunc { actualExpression, failureMessage in
        failureMessage.postfixMessage = "be one of: \(stringify(allowedValues))"
        if let actualValue = actualExpression.evaluate() {
            return contains(allowedValues, actualValue)
        }
        return false
    }
}
