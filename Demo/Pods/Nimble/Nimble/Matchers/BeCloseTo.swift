import Foundation

func _isCloseTo(actualValue: Double?, expectedValue: Double, delta: Double, failureMessage: FailureMessage) -> Bool {
    failureMessage.postfixMessage = "be close to <\(stringify(expectedValue))> (within \(stringify(delta)))"
    if actualValue != nil {
        failureMessage.actualValue = "<\(stringify(actualValue!))>"
    } else {
        failureMessage.actualValue = "<nil>"
    }
    return actualValue != nil && abs(actualValue! - expectedValue) < delta
}

public func beCloseTo(expectedValue: Double, within delta: Double = 0.0001) -> MatcherFunc<Double> {
    return MatcherFunc { actualExpression, failureMessage in
        return _isCloseTo(actualExpression.evaluate(), expectedValue, delta, failureMessage)
    }
}

public func beCloseTo(expectedValue: NMBDoubleConvertible, within delta: Double = 0.0001) -> MatcherFunc<NMBDoubleConvertible> {
    return MatcherFunc { actualExpression, failureMessage in
        return _isCloseTo(actualExpression.evaluate()?.doubleValue, expectedValue.doubleValue, delta, failureMessage)
    }
}

@objc public class NMBObjCBeCloseToMatcher : NMBMatcher {
    var _expected: NSNumber
    var _delta: CDouble
    init(expected: NSNumber, within: CDouble) {
        _expected = expected
        _delta = within
    }

    public func matches(actualExpression: () -> NSObject!, failureMessage: FailureMessage, location: SourceLocation) -> Bool {
        let actualBlock: () -> NMBDoubleConvertible? = ({
            return actualExpression() as? NMBDoubleConvertible
        })
        let expr = Expression(expression: actualBlock, location: location)
        return beCloseTo(self._expected, within: self._delta).matches(expr, failureMessage: failureMessage)
    }

    public var within: (CDouble) -> NMBObjCBeCloseToMatcher {
        return ({ delta in
            return NMBObjCBeCloseToMatcher(expected: self._expected, within: delta)
        })
    }
}

extension NMBObjCMatcher {
    public class func beCloseToMatcher(expected: NSNumber, within: CDouble) -> NMBObjCBeCloseToMatcher {
        return NMBObjCBeCloseToMatcher(expected: expected, within: within)
    }
}
