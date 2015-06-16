import Foundation


/// A Nimble matcher that succeeds when the actual sequence's first element
/// is equal to the expected value.
public func beginWith<S: SequenceType, T: Equatable where S.Generator.Element == T>(startingElement: T) -> NonNilMatcherFunc<S> {
    return NonNilMatcherFunc { actualExpression, failureMessage in
        failureMessage.postfixMessage = "begin with <\(startingElement)>"
        if let actualValue = actualExpression.evaluate() {
            var actualGenerator = actualValue.generate()
            return actualGenerator.next() == startingElement
        }
        return false
    }
}

/// A Nimble matcher that succeeds when the actual collection's first element
/// is equal to the expected object.
public func beginWith(startingElement: AnyObject) -> NonNilMatcherFunc<NMBOrderedCollection> {
    return NonNilMatcherFunc { actualExpression, failureMessage in
        failureMessage.postfixMessage = "begin with <\(startingElement)>"
        let collection = actualExpression.evaluate()
        return collection != nil && collection!.indexOfObject(startingElement) == 0
    }
}

/// A Nimble matcher that succeeds when the actual string contains expected substring
/// where the expected substring's location is zero.
public func beginWith(startingSubstring: String) -> NonNilMatcherFunc<String> {
    return NonNilMatcherFunc { actualExpression, failureMessage in
        failureMessage.postfixMessage = "begin with <\(startingSubstring)>"
        if let actual = actualExpression.evaluate() {
            let range = actual.rangeOfString(startingSubstring)
            return range != nil && range!.startIndex == actual.startIndex
        }
        return false
    }
}

extension NMBObjCMatcher {
    public class func beginWithMatcher(expected: AnyObject) -> NMBObjCMatcher {
        return NMBObjCMatcher(canMatchNil: false) { actualExpression, failureMessage, location in
            let actual = actualExpression.evaluate()
            if let actualString = actual as? String {
                let expr = actualExpression.cast { $0 as? String }
                return beginWith(expected as! String).matches(expr, failureMessage: failureMessage)
            } else {
                let expr = actualExpression.cast { $0 as? NMBOrderedCollection }
                return beginWith(expected).matches(expr, failureMessage: failureMessage)
            }
        }
    }
}
