import Foundation

/// A Nimble matcher that succeeds when the actual value is an instance of the given class.
/// @see beAnInstanceOf if you want to match against the exact class
public func beAKindOf(expectedClass: AnyClass) -> NonNilMatcherFunc<NSObject> {
    return NonNilMatcherFunc { actualExpression, failureMessage in
        let instance = actualExpression.evaluate()
        if let validInstance = instance {
            failureMessage.actualValue = "<\(NSStringFromClass(validInstance.dynamicType)) instance>"
        } else {
            failureMessage.actualValue = "<nil>"
        }
        failureMessage.postfixMessage = "be a kind of \(NSStringFromClass(expectedClass))"
        return instance != nil && instance!.isKindOfClass(expectedClass)
    }
}

extension NMBObjCMatcher {
    public class func beAKindOfMatcher(expected: AnyClass) -> NMBMatcher {
        return NMBObjCMatcher(canMatchNil: false) { actualExpression, failureMessage, location in
            return beAKindOf(expected).matches(actualExpression, failureMessage: failureMessage)
        }
    }
}
