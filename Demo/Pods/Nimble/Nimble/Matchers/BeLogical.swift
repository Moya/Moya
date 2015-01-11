import Foundation

func _beBool(#expectedValue: BooleanType, #stringValue: String, #falseMatchesNil: Bool) -> MatcherFunc<BooleanType> {
    return MatcherFunc { actualExpression, failureMessage in
        failureMessage.postfixMessage = "be \(stringValue)"
        let actual = actualExpression.evaluate()
        if expectedValue {
            return actual?.boolValue == expectedValue.boolValue
        } else if !falseMatchesNil {
            return actual != nil && actual!.boolValue != !expectedValue.boolValue
        } else {
            return actual?.boolValue != !expectedValue.boolValue
        }
    }
}

// mark: beTrue() / beFalse()

public func beTrue() -> MatcherFunc<Bool> {
    return equal(true).withFailureMessage { failureMessage in
        failureMessage.postfixMessage = "be true"
    }
}

public func beFalse() -> MatcherFunc<Bool> {
    return equal(false).withFailureMessage { failureMessage in
        failureMessage.postfixMessage = "be false"
    }
}

// mark: beTruthy() / beFalsy()

public func beTruthy() -> MatcherFunc<BooleanType> {
    return _beBool(expectedValue: true, stringValue: "truthy", falseMatchesNil: true)
}

public func beFalsy() -> MatcherFunc<BooleanType> {
    return _beBool(expectedValue: false, stringValue: "falsy", falseMatchesNil: true)
}

extension NMBObjCMatcher {
    public class func beTruthyMatcher() -> NMBObjCMatcher {
        return NMBObjCMatcher { actualBlock, failureMessage, location in
            let block = ({ (actualBlock() as? NSNumber)?.boolValue ?? false as BooleanType? })
            let expr = Expression(expression: block, location: location)
            return beTruthy().matches(expr, failureMessage: failureMessage)
        }
    }

    public class func beFalsyMatcher() -> NMBObjCMatcher {
        return NMBObjCMatcher { actualBlock, failureMessage, location in
            let block = ({ (actualBlock() as? NSNumber)?.boolValue ?? false as BooleanType? })
            let expr = Expression(expression: block, location: location)
            return beFalsy().matches(expr, failureMessage: failureMessage)
        }
    }

    public class func beTrueMatcher() -> NMBObjCMatcher {
        return NMBObjCMatcher { actualBlock, failureMessage, location in
            let block = ({ (actualBlock() as? NSNumber)?.boolValue as Bool? })
            let expr = Expression(expression: block, location: location)
            return beTrue().matches(expr, failureMessage: failureMessage)
        }
    }

    public class func beFalseMatcher() -> NMBObjCMatcher {
        return NMBObjCMatcher { actualBlock, failureMessage, location in
            let block = ({ (actualBlock() as? NSNumber)?.boolValue as Bool? })
            let expr = Expression(expression: block, location: location)
            return beFalse().matches(expr, failureMessage: failureMessage)
        }
    }
}
