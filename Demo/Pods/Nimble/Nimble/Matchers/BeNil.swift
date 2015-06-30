import Foundation

/// A Nimble matcher that succeeds when the actual value is nil.
public func beNil<T>() -> MatcherFunc<T> {
    return MatcherFunc { actualExpression, failureMessage in
        failureMessage.postfixMessage = "be nil"
        let actualValue = actualExpression.evaluate()
        return actualValue == nil
    }
}

extension NMBObjCMatcher {
    public class func beNilMatcher() -> NMBObjCMatcher {
        return NMBObjCMatcher { actualExpression, failureMessage in
            return beNil().matches(actualExpression, failureMessage: failureMessage)
        }
    }
}
