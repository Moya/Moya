import Foundation

public func beAnInstanceOf(expectedClass: AnyClass) -> MatcherFunc<NSObject> {
    return MatcherFunc { actualExpression, failureMessage in
        let instance = actualExpression.evaluate()
        if let validInstance = instance {
            failureMessage.actualValue = "<\(NSStringFromClass(validInstance.dynamicType)) instance>"
        } else {
            failureMessage.actualValue = "<nil>"
        }
        failureMessage.postfixMessage = "be an instance of \(NSStringFromClass(expectedClass))"
        return instance != nil && instance!.isMemberOfClass(expectedClass)
    }
}

extension NMBObjCMatcher {
    public class func beAnInstanceOfMatcher(expected: AnyClass) -> NMBMatcher {
        return NMBObjCMatcher { actualExpression, failureMessage, location in
            let expr = Expression(expression: actualExpression, location: location)
            return beAnInstanceOf(expected).matches(expr, failureMessage: failureMessage)
        }
    }
}
