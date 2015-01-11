import Foundation

public func beLessThanOrEqualTo<T: Comparable>(expectedValue: T?) -> MatcherFunc<T> {
    return MatcherFunc { actualExpression, failureMessage in
        failureMessage.postfixMessage = "be less than or equal to <\(stringify(expectedValue))>"
        return actualExpression.evaluate() <= expectedValue
    }
}

public func beLessThanOrEqualTo<T: NMBComparable>(expectedValue: T?) -> MatcherFunc<T> {
    return MatcherFunc { actualExpression, failureMessage in
        failureMessage.postfixMessage = "be less than or equal to <\(stringify(expectedValue))>"
        let actualValue = actualExpression.evaluate()
        return actualValue != nil && actualValue!.NMB_compare(expectedValue) != NSComparisonResult.OrderedDescending
    }
}

public func <=<T: Comparable>(lhs: Expectation<T>, rhs: T) {
    lhs.to(beLessThanOrEqualTo(rhs))
}

public func <=<T: NMBComparable>(lhs: Expectation<T>, rhs: T) {
    lhs.to(beLessThanOrEqualTo(rhs))
}

extension NMBObjCMatcher {
    public class func beLessThanOrEqualToMatcher(expected: NMBComparable?) -> NMBObjCMatcher {
        return NMBObjCMatcher { actualBlock, failureMessage, location in
            let block = ({ actualBlock() as NMBComparable? })
            let expr = Expression(expression: block, location: location)
            return beLessThanOrEqualTo(expected).matches(expr, failureMessage: failureMessage)
        }
    }
}
