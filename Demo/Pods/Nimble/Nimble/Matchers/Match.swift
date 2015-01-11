import Foundation

public func match(expectedValue:String?) -> MatcherFunc<String> {
    return MatcherFunc { actualExpression, failureMessage in
        failureMessage.postfixMessage = "match <\(stringify(expectedValue))>"
        
        if let actual = actualExpression.evaluate() {
            if let regexp = expectedValue {
                return actual.rangeOfString(regexp, options: .RegularExpressionSearch) != nil
            }
        }

        return false
    }
}

extension NMBObjCMatcher {
    public class func matchMatcher(expected: NSString) -> NMBMatcher {
        return NMBObjCMatcher { actualBlock, failureMessage, location in
            let actual = actualBlock()
            if let actualString = actual as? String {
                let expr = Expression(expression: ({ actualString }), location: location)
                return match(expected).matches(expr, failureMessage: failureMessage)
            }
            return false
        }
    }
}

