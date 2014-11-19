import Foundation

public func beLessThan<T: Comparable>(expectedValue: T?) -> MatcherFunc<T> {
    return MatcherFunc { actualExpression, failureMessage in
        failureMessage.postfixMessage = "be less than <\(stringify(expectedValue))>"
        return actualExpression.evaluate() < expectedValue
    }
}

public func beLessThan(expectedValue: NMBComparable?) -> MatcherFunc<NMBComparable> {
    return MatcherFunc { actualExpression, failureMessage in
        failureMessage.postfixMessage = "be less than <\(stringify(expectedValue))>"
        let actualValue = actualExpression.evaluate()
        let matches = actualValue != nil && actualValue!.NMB_compare(expectedValue) == NSComparisonResult.OrderedAscending
        return matches
    }
}

public func <<T: Comparable>(lhs: Expectation<T>, rhs: T) {
    lhs.to(beLessThan(rhs))
}

public func <(lhs: Expectation<NMBComparable>, rhs: NMBComparable?) {
    lhs.to(beLessThan(rhs))
}

extension NMBObjCMatcher {
    public class func beLessThanMatcher(expected: NMBComparable?) -> NMBObjCMatcher {
        return NMBObjCMatcher { actualBlock, failureMessage, location in
            let block = ({ actualBlock() as NMBComparable? })
            let expr = Expression(expression: block, location: location)
            return beLessThan(expected).matches(expr, failureMessage: failureMessage)
        }
    }
}
