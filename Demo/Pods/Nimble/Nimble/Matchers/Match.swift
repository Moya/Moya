import Foundation

/// A Nimble matcher that succeeds when the actual string satisfies the regular expression
/// described by the expected string.
public func match(expectedValue: String?) -> NonNilMatcherFunc<String> {
    return NonNilMatcherFunc { actualExpression, failureMessage in
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
        return NMBObjCMatcher(canMatchNil: false) { actualExpression, failureMessage, location in
            let actual = actualExpression.cast { $0 as? String }
            return match(expected.description).matches(actual, failureMessage: failureMessage)
        }
    }
}

