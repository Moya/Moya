import Foundation


/// A Nimble matcher that succeeds when a value is "empty". For collections, this
/// means the are no items in that collection. For strings, it is an empty string.
public func beEmpty<S: SequenceType>() -> NonNilMatcherFunc<S> {
    return NonNilMatcherFunc { actualExpression, failureMessage in
        failureMessage.postfixMessage = "be empty"
        let actualSeq = actualExpression.evaluate()
        if actualSeq == nil {
            return true
        }
        var generator = actualSeq!.generate()
        return generator.next() == nil
    }
}

/// A Nimble matcher that succeeds when a value is "empty". For collections, this
/// means the are no items in that collection. For strings, it is an empty string.
public func beEmpty() -> NonNilMatcherFunc<NSString> {
    return NonNilMatcherFunc { actualExpression, failureMessage in
        failureMessage.postfixMessage = "be empty"
        let actualString = actualExpression.evaluate()
        return actualString == nil || actualString!.length == 0
    }
}

// Without specific overrides, beEmpty() is ambiguous for NSDictionary, NSArray,
// etc, since they conform to SequenceType as well as NMBCollection.

/// A Nimble matcher that succeeds when a value is "empty". For collections, this
/// means the are no items in that collection. For strings, it is an empty string.
public func beEmpty() -> NonNilMatcherFunc<NSDictionary> {
	return NonNilMatcherFunc { actualExpression, failureMessage in
		failureMessage.postfixMessage = "be empty"
		let actualDictionary = actualExpression.evaluate()
		return actualDictionary == nil || actualDictionary!.count == 0
	}
}

/// A Nimble matcher that succeeds when a value is "empty". For collections, this
/// means the are no items in that collection. For strings, it is an empty string.
public func beEmpty() -> NonNilMatcherFunc<NSArray> {
	return NonNilMatcherFunc { actualExpression, failureMessage in
		failureMessage.postfixMessage = "be empty"
		let actualArray = actualExpression.evaluate()
		return actualArray == nil || actualArray!.count == 0
	}
}

/// A Nimble matcher that succeeds when a value is "empty". For collections, this
/// means the are no items in that collection. For strings, it is an empty string.
public func beEmpty() -> NonNilMatcherFunc<NMBCollection> {
    return NonNilMatcherFunc { actualExpression, failureMessage in
        failureMessage.postfixMessage = "be empty"
        let actual = actualExpression.evaluate()
        return actual == nil || actual!.count == 0
    }
}

extension NMBObjCMatcher {
    public class func beEmptyMatcher() -> NMBObjCMatcher {
        return NMBObjCMatcher(canMatchNil: false) { actualExpression, failureMessage, location in
            let actualValue = actualExpression.evaluate()
            failureMessage.postfixMessage = "be empty"
            if let value = actualValue as? NMBCollection {
                let expr = Expression(expression: ({ value as NMBCollection }), location: location)
                return beEmpty().matches(expr, failureMessage: failureMessage)
            } else if let value = actualValue as? NSString {
                let expr = Expression(expression: ({ value as String }), location: location)
                return beEmpty().matches(expr, failureMessage: failureMessage)
            } else if let actualValue = actualValue {
                failureMessage.postfixMessage = "be empty (only works for NSArrays, NSSets, NSDictionaries, NSHashTables, and NSStrings)"
                failureMessage.actualValue = "\(NSStringFromClass(actualValue.dynamicType)) type"
            }
            return false
        }
    }
}
