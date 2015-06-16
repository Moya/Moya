import Foundation


/// Implement this protocol if you want full control over to() and toNot() behaviors
/// when matching a value.
public protocol Matcher {
    typealias ValueType
    func matches(actualExpression: Expression<ValueType>, failureMessage: FailureMessage) -> Bool
    func doesNotMatch(actualExpression: Expression<ValueType>, failureMessage: FailureMessage) -> Bool
}

/// Implement this protocol if you just want a simplier matcher. The negation
/// is provided for you automatically.
///
/// If you just want a very simplified usage of BasicMatcher,
/// @see MatcherFunc.
public protocol BasicMatcher {
    typealias ValueType
    func matches(actualExpression: Expression<ValueType>, failureMessage: FailureMessage) -> Bool
}


/// Implement this protocol if you want a matcher only work for non-nil values.
/// The matcher still needs to properly handle nil values, but using this type will
/// tell Nimble to automatically postfix a nil match error (and automatically fail the match).
///
/// Unlike a naive implementation of the matches interface, NonNilBasicMatcher will also
/// fail for the negation to a nil:
///
///   // objc
///   expect(nil).to(matchWithMyCustomNonNilBasicMatcher()) // => fails
///   expect(nil).toNot(matchWithMyCustomNonNilBasicMatcher()) // => fails
///
/// @see BasicMatcher
public protocol NonNilBasicMatcher {
    typealias ValueType
    func matches(actualExpression: Expression<ValueType>, failureMessage: FailureMessage) -> Bool
}

/// Objective-C interface to the Swift variant of Matcher. This gives you full control over
/// to() and toNot() behaviors when matching a value.
@objc public protocol NMBMatcher {
    func matches(actualBlock: () -> NSObject!, failureMessage: FailureMessage, location: SourceLocation) -> Bool
    func doesNotMatch(actualBlock: () -> NSObject!, failureMessage: FailureMessage, location: SourceLocation) -> Bool
}

/// Protocol for types that support contain() matcher.
@objc public protocol NMBContainer {
    func containsObject(object: AnyObject!) -> Bool
}
extension NSArray : NMBContainer {}
extension NSSet : NMBContainer {}
extension NSHashTable : NMBContainer {}

/// Protocol for types that support only beEmpty()
@objc public protocol NMBCollection {
    var count: Int { get }
}
extension NSSet : NMBCollection {}
extension NSDictionary : NMBCollection {}
extension NSHashTable : NMBCollection {}

/// Protocol for types that support beginWith(), endWith(), beEmpty() matchers
@objc public protocol NMBOrderedCollection : NMBCollection {
    func indexOfObject(object: AnyObject!) -> Int
}
extension NSArray : NMBOrderedCollection {}

/// Protocol for types to support beCloseTo() matcher
@objc public protocol NMBDoubleConvertible {
    var doubleValue: CDouble { get }
}
extension NSNumber : NMBDoubleConvertible { }
extension NSDecimalNumber : NMBDoubleConvertible { } // TODO: not the best to downsize

/// Protocol for types to support beLessThan(), beLessThanOrEqualTo(),
///  beGreaterThan(), beGreaterThanOrEqualTo(), and equal() matchers.
///
/// Types that conform to Swift's Comparable protocol will work implicitly too
@objc public protocol NMBComparable {
    func NMB_compare(otherObject: NMBComparable!) -> NSComparisonResult
}
extension NSNumber : NMBComparable {
    public func NMB_compare(otherObject: NMBComparable!) -> NSComparisonResult {
        return compare(otherObject as! NSNumber)
    }
}
extension NSString : NMBComparable {
    public func NMB_compare(otherObject: NMBComparable!) -> NSComparisonResult {
        return compare(otherObject as! String)
    }
}
