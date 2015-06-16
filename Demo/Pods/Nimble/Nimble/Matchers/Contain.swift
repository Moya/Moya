import Foundation

/// A Nimble matcher that succeeds when the actual sequence contains the expected value.
public func contain<S: SequenceType, T: Equatable where S.Generator.Element == T>(items: T...) -> NonNilMatcherFunc<S> {
    return NonNilMatcherFunc { actualExpression, failureMessage in
        failureMessage.postfixMessage = "contain <\(arrayAsString(items))>"
        if let actual = actualExpression.evaluate() {
            return all(items) {
                return contains(actual, $0)
            }
        }
        return false
    }
}

/// A Nimble matcher that succeeds when the actual string contains the expected substring.
public func contain(substrings: String...) -> NonNilMatcherFunc<String> {
    return NonNilMatcherFunc { actualExpression, failureMessage in
        failureMessage.postfixMessage = "contain <\(arrayAsString(substrings))>"
        if let actual = actualExpression.evaluate() {
            return all(substrings) {
                let scanRange = Range(start: actual.startIndex, end: actual.endIndex)
                let range = actual.rangeOfString($0, options: nil, range: scanRange, locale: nil)
                return range != nil && !range!.isEmpty
            }
        }
        return false
    }
}

/// A Nimble matcher that succeeds when the actual string contains the expected substring.
public func contain(substrings: NSString...) -> NonNilMatcherFunc<NSString> {
    return NonNilMatcherFunc { actualExpression, failureMessage in
        failureMessage.postfixMessage = "contain <\(arrayAsString(substrings))>"
        if let actual = actualExpression.evaluate() {
            return all(substrings) {
                return actual.containsString($0.description)
            }
        }
        return false
    }
}

/// A Nimble matcher that succeeds when the actual collection contains the expected object.
public func contain(items: AnyObject?...) -> NonNilMatcherFunc<NMBContainer> {
    return NonNilMatcherFunc { actualExpression, failureMessage in
        failureMessage.postfixMessage = "contain <\(arrayAsString(items))>"
        let actual = actualExpression.evaluate()
        return all(items) { item in
            return actual != nil && actual!.containsObject(item)
        }
    }
}

extension NMBObjCMatcher {
    public class func containMatcher(expected: NSObject?) -> NMBObjCMatcher {
        return NMBObjCMatcher(canMatchNil: false) { actualExpression, failureMessage, location in
            let actualValue = actualExpression.evaluate()
            if let value = actualValue as? NMBContainer {
                let expr = Expression(expression: ({ value as NMBContainer }), location: location)
                return contain(expected).matches(expr, failureMessage: failureMessage)
            } else if let value = actualValue as? NSString {
                let expr = Expression(expression: ({ value as String }), location: location)
                return contain(expected as! String).matches(expr, failureMessage: failureMessage)
            } else if actualValue != nil {
                failureMessage.postfixMessage = "contain <\(stringify(expected))> (only works for NSArrays, NSSets, NSHashTables, and NSStrings)"
            } else {
                failureMessage.postfixMessage = "contain <\(stringify(expected))>"
            }
            return false
        }
    }
}
