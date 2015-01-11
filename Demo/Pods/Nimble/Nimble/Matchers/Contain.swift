import Foundation

public func contain<S: SequenceType, T: Equatable where S.Generator.Element == T>(items: T...) -> MatcherFunc<S> {
    return MatcherFunc { actualExpression, failureMessage in
        failureMessage.postfixMessage = "contain <\(_arrayAsString(items))>"
        if let actual = actualExpression.evaluate() {
            return _all(items) {
                return contains(actual, $0)
            }
        }
        return false
    }
}

public func contain(substrings: String...) -> MatcherFunc<String> {
    return MatcherFunc { actualExpression, failureMessage in
        failureMessage.postfixMessage = "contain <\(_arrayAsString(substrings))>"
        if let actual = actualExpression.evaluate() {
            return _all(substrings) {
                let scanRange = Range(start: actual.startIndex, end: actual.endIndex)
                let range = actual.rangeOfString($0, options: nil, range: scanRange, locale: nil)
                return range != nil && !range!.isEmpty
            }
        }
        return false
    }
}

public func contain(items: AnyObject?...) -> MatcherFunc<NMBContainer> {
    return MatcherFunc { actualExpression, failureMessage in
        failureMessage.postfixMessage = "contain <\(_arrayAsString(items))>"
        let actual = actualExpression.evaluate()
        return _all(items) { item in
            return actual != nil && actual!.containsObject(item)
        }
    }
}

extension NMBObjCMatcher {
    public class func containMatcher(expected: NSObject?) -> NMBObjCMatcher {
        return NMBObjCMatcher { actualBlock, failureMessage, location in
            let actualValue = actualBlock()
            if let value = actualValue as? NMBContainer {
                let expr = Expression(expression: ({ value as NMBContainer }), location: location)
                return contain(expected).matches(expr, failureMessage: failureMessage)
            } else if let value = actualValue as? NSString {
                let expr = Expression(expression: ({ value as String }), location: location)
                return contain(expected as String).matches(expr, failureMessage: failureMessage)
            } else {
                failureMessage.postfixMessage = "contain \(expected) (only works for NSArrays, NSSets, NSHashTables, and NSStrings)"
                return false
            }
        }
    }
}
