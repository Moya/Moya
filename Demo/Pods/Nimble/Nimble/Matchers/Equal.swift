import Foundation


public func equal<T: Equatable>(expectedValue: T?) -> MatcherFunc<T> {
    return MatcherFunc { actualExpression, failureMessage in
        failureMessage.postfixMessage = "equal <\(stringify(expectedValue))>"
        let matches = actualExpression.evaluate() == expectedValue && expectedValue != nil
        if expectedValue == nil || actualExpression.evaluate() == nil {
            failureMessage.postfixMessage += " (will not match nils, use beNil() instead)"
            return false
        }
        return matches
    }
}

// perhaps try to extend to SequenceOf or Sequence types instead of dictionaries
public func equal<T: Equatable, C: Equatable>(expectedValue: [T: C]?) -> MatcherFunc<[T: C]> {
    return MatcherFunc { actualExpression, failureMessage in
        failureMessage.postfixMessage = "equal <\(stringify(expectedValue))>"
        if expectedValue == nil || actualExpression.evaluate() == nil {
            failureMessage.postfixMessage += " (will not match nils, use beNil() instead)"
            return false
        }
        var expectedGen = expectedValue!.generate()
        var actualGen = actualExpression.evaluate()!.generate()

        var expectedItem = expectedGen.next()
        var actualItem = actualGen.next()
        var matches = elementsAreEqual(expectedItem, actualItem)
        while (matches && (actualItem != nil || expectedItem != nil)) {
            actualItem = actualGen.next()
            expectedItem = expectedGen.next()
            matches = elementsAreEqual(expectedItem, actualItem)
        }
        return matches
    }
}

// perhaps try to extend to SequenceOf or Sequence types instead of arrays
public func equal<T: Equatable>(expectedValue: [T]?) -> MatcherFunc<[T]> {
    return MatcherFunc { actualExpression, failureMessage in
        failureMessage.postfixMessage = "equal <\(stringify(expectedValue))>"
        if expectedValue == nil || actualExpression.evaluate() == nil {
            failureMessage.postfixMessage += " (will not match nils, use beNil() instead)"
            return false
        }
        var expectedGen = expectedValue!.generate()
        var actualGen = actualExpression.evaluate()!.generate()
        var expectedItem = expectedGen.next()
        var actualItem = actualGen.next()
        var matches = actualItem == expectedItem
        while (matches && (actualItem != nil || expectedItem != nil)) {
            actualItem = actualGen.next()
            expectedItem = expectedGen.next()
            matches = actualItem == expectedItem
        }
        return matches
    }
}

public func ==<T: Equatable>(lhs: Expectation<T>, rhs: T?) {
    lhs.to(equal(rhs))
}

public func !=<T: Equatable>(lhs: Expectation<T>, rhs: T?) {
    lhs.toNot(equal(rhs))
}

public func ==<T: Equatable>(lhs: Expectation<[T]>, rhs: [T]?) {
    lhs.to(equal(rhs))
}

public func !=<T: Equatable>(lhs: Expectation<[T]>, rhs: [T]?) {
    lhs.toNot(equal(rhs))
}

public func ==<T: Equatable, C: Equatable>(lhs: Expectation<[T: C]>, rhs: [T: C]?) {
    lhs.to(equal(rhs))
}

public func !=<T: Equatable, C: Equatable>(lhs: Expectation<[T: C]>, rhs: [T: C]?) {
    lhs.toNot(equal(rhs))
}

extension NMBObjCMatcher {
    public class func equalMatcher(expected: NSObject) -> NMBMatcher {
        return NMBObjCMatcher { actualExpression, failureMessage, location in
            let expr = Expression(expression: actualExpression, location: location)
            return equal(expected).matches(expr, failureMessage: failureMessage)
        }
    }
}


internal func elementsAreEqual<T: Equatable, C: Equatable>(a: (T, C)?, b: (T, C)?) -> Bool {
    if a == nil || b == nil {
        return a == nil && b == nil
    } else {
        let (aKey, aValue) = a!
        let (bKey, bValue) = b!
        return (aKey == bKey && aValue == bValue)
    }
}

