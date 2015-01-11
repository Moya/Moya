import Foundation

public func beginWith<S: SequenceType, T: Equatable where S.Generator.Element == T>(startingElement: T) -> MatcherFunc<S> {
    return MatcherFunc { actualExpression, failureMessage in
        failureMessage.postfixMessage = "begin with <\(startingElement)>"
        if let actualValue = actualExpression.evaluate() {
            var actualGenerator = actualValue.generate()
            return actualGenerator.next() == startingElement
        }
        return false
    }
}

public func beginWith(startingElement: AnyObject) -> MatcherFunc<NMBOrderedCollection> {
    return MatcherFunc { actualExpression, failureMessage in
        failureMessage.postfixMessage = "begin with <\(startingElement)>"
        let collection = actualExpression.evaluate()
        return collection != nil && collection!.indexOfObject(startingElement) == 0
    }
}

public func beginWith(startingSubstring: String) -> MatcherFunc<String> {
    return MatcherFunc { actualExpression, failureMessage in
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
        return NMBObjCMatcher { actualBlock, failureMessage, location in
            let actual = actualBlock()
            if let actualString = actual as? String {
                let expr = Expression(expression: ({ actualString }), location: location)
                return beginWith(expected as NSString).matches(expr, failureMessage: failureMessage)
            } else {
                let expr = Expression(expression: ({ actual as? NMBOrderedCollection }), location: location)
                return beginWith(expected).matches(expr, failureMessage: failureMessage)
            }
        }
    }
}
