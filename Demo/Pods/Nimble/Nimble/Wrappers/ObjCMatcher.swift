import Foundation

struct ObjCMatcherWrapper : Matcher {
    let matcher: NMBMatcher
    let to: String
    let toNot: String

    func matches(actualExpression: Expression<NSObject>, failureMessage: FailureMessage) -> Bool {
        failureMessage.to = to
        return matcher.matches(({ actualExpression.evaluate() }), failureMessage: failureMessage, location: actualExpression.location)
    }

    func doesNotMatch(actualExpression: Expression<NSObject>, failureMessage: FailureMessage) -> Bool {
        failureMessage.to = toNot
        return matcher.doesNotMatch(({ actualExpression.evaluate() }), failureMessage: failureMessage, location: actualExpression.location)
    }
}

// Equivalent to Expectation, but simplified for ObjC objects only
public class NMBExpectation : NSObject {
    let _actualBlock: () -> NSObject!
    var _negative: Bool
    let _file: String
    let _line: UInt
    var _timeout: NSTimeInterval = 1.0

    public init(actualBlock: () -> NSObject!, negative: Bool, file: String, line: UInt) {
        self._actualBlock = actualBlock
        self._negative = negative
        self._file = file
        self._line = line
    }

    public var withTimeout: (NSTimeInterval) -> NMBExpectation {
        return ({ timeout in self._timeout = timeout
            return self
        })
    }

    public var to: (matcher: NMBMatcher) -> Void {
        return ({ matcher in
            expect(file: self._file, line: self._line){ self._actualBlock() as NSObject? }.to(
                ObjCMatcherWrapper(matcher: matcher, to: "to", toNot: "to not")
            )
        })
    }

    public var toNot: (matcher: NMBMatcher) -> Void {
        return ({ matcher in
            expect(file: self._file, line: self._line){ self._actualBlock() as NSObject? }.toNot(
                ObjCMatcherWrapper(matcher: matcher, to: "to", toNot: "to not")
            )
        })
    }

    public var notTo: (matcher: NMBMatcher) -> Void { return toNot }

    public var toEventually: (matcher: NMBMatcher) -> Void {
        return ({ matcher in
            expect(file: self._file, line: self._line){ self._actualBlock() as NSObject? }.toEventually(
                ObjCMatcherWrapper(matcher: matcher, to: "to", toNot: "to not"),
                timeout: self._timeout
            )
        })
    }

    public var toEventuallyNot: (matcher: NMBMatcher) -> Void {
        return ({ matcher in
            expect(file: self._file, line: self._line){ self._actualBlock() as NSObject? }.toEventuallyNot(
                ObjCMatcherWrapper(matcher: matcher, to: "to", toNot: "to not"),
                timeout: self._timeout
            )
        })
    }
}

typealias MatcherBlock = (actualExpression: Expression<NSObject>, failureMessage: FailureMessage, location: SourceLocation) -> Bool
typealias FullMatcherBlock = (actualExpression: Expression<NSObject>, failureMessage: FailureMessage, location: SourceLocation, shouldNotMatch: Bool) -> Bool
@objc public class NMBObjCMatcher : NMBMatcher {
    let _match: MatcherBlock
    let _doesNotMatch: MatcherBlock
    let canMatchNil: Bool

    init(canMatchNil: Bool, matcher: MatcherBlock, notMatcher: MatcherBlock) {
        self.canMatchNil = canMatchNil
        self._match = matcher
        self._doesNotMatch = notMatcher
    }

    convenience init(matcher: MatcherBlock) {
        self.init(canMatchNil: true, matcher: matcher)
    }

    convenience init(canMatchNil: Bool, matcher: MatcherBlock) {
        self.init(canMatchNil: canMatchNil, matcher: matcher, notMatcher: ({ actualExpression, failureMessage, location in
            return !matcher(actualExpression: actualExpression, failureMessage: failureMessage, location: location)
        }))
    }

    convenience init(matcher: FullMatcherBlock) {
        self.init(canMatchNil: true, matcher: matcher)
    }

    convenience init(canMatchNil: Bool, matcher: FullMatcherBlock) {
        self.init(canMatchNil: canMatchNil, matcher: ({ actualExpression, failureMessage, location in
            return matcher(actualExpression: actualExpression, failureMessage: failureMessage, location: location, shouldNotMatch: false)
        }), notMatcher: ({ actualExpression, failureMessage, location in
            return matcher(actualExpression: actualExpression, failureMessage: failureMessage, location: location, shouldNotMatch: true)
        }))
    }

    private func canMatch(actualExpression: Expression<NSObject>, failureMessage: FailureMessage) -> Bool {
        if !canMatchNil && actualExpression.evaluate() == nil {
            failureMessage.postfixActual = " (use beNil() to match nils)"
            return false
        }
        return true
    }

    public func matches(actualBlock: () -> NSObject!, failureMessage: FailureMessage, location: SourceLocation) -> Bool {
        let expr = Expression(expression: actualBlock, location: SourceLocation())
        let result = _match(
            actualExpression: expr,
            failureMessage: failureMessage,
            location: location)
        if self.canMatch(Expression(expression: actualBlock, location: location), failureMessage: failureMessage) {
            return result
        } else {
            return false
        }
    }

    public func doesNotMatch(actualBlock: () -> NSObject!, failureMessage: FailureMessage, location: SourceLocation) -> Bool {
        let expr = Expression(expression: actualBlock, location: SourceLocation())
        let result = _doesNotMatch(
            actualExpression: expr,
            failureMessage: failureMessage,
            location: location)
        if self.canMatch(Expression(expression: actualBlock, location: location), failureMessage: failureMessage) {
            return result
        } else {
            return false
        }
    }
}

