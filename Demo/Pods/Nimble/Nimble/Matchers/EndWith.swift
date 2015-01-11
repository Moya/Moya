import Foundation

public func endWith<S: SequenceType, T: Equatable where S.Generator.Element == T>(endingElement: T) -> MatcherFunc<S> {
    return MatcherFunc { actualExpression, failureMessage in
        failureMessage.postfixMessage = "end with <\(endingElement)>"

        if let actualValue = actualExpression.evaluate() {
            var actualGenerator = actualValue.generate()
            var lastItem: T?
            var item: T?
            do {
                lastItem = item
                item = actualGenerator.next()
            } while(item != nil)
            
            return lastItem == endingElement
        }
        return false
    }
}

public func endWith(endingElement: AnyObject) -> MatcherFunc<NMBOrderedCollection> {
    return MatcherFunc { actualExpression, failureMessage in
        failureMessage.postfixMessage = "end with <\(endingElement)>"
        let collection = actualExpression.evaluate()
        return collection != nil && collection!.indexOfObject(endingElement) == collection!.count - 1
    }
}

public func endWith(endingSubstring: String) -> MatcherFunc<String> {
    return MatcherFunc { actualExpression, failureMessage in
        failureMessage.postfixMessage = "end with <\(endingSubstring)>"
        if let collection = actualExpression.evaluate() {
            let range = collection.rangeOfString(endingSubstring)
            return range != nil && range!.endIndex == collection.endIndex
        }
        return false
    }
}

extension NMBObjCMatcher {
    public class func endWithMatcher(expected: AnyObject) -> NMBObjCMatcher {
        return NMBObjCMatcher { actualBlock, failureMessage, location in
            let actual = actualBlock()
            if let actualString = actual as? String {
                let expr = Expression(expression: ({ actualString }), location: location)
                return endWith(expected as NSString).matches(expr, failureMessage: failureMessage)
            } else {
                let expr = Expression(expression: ({ actual as? NMBOrderedCollection }), location: location)
                return endWith(expected).matches(expr, failureMessage: failureMessage)
            }
        }
    }
}
