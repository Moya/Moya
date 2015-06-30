import Foundation

internal func expressionMatches<T, U where U: Matcher, U.ValueType == T>(expression: Expression<T>, matcher: U, #to: String) -> (Bool, FailureMessage) {
    var msg = FailureMessage()
    msg.to = to
    let pass = matcher.matches(expression, failureMessage: msg)
    if msg.actualValue == "" {
        msg.actualValue = "<\(stringify(expression.evaluate()))>"
    }
    return (pass, msg)
}

internal func expressionDoesNotMatch<T, U where U: Matcher, U.ValueType == T>(expression: Expression<T>, matcher: U, #toNot: String) -> (Bool, FailureMessage) {
    var msg = FailureMessage()
    msg.to = toNot
    let pass = matcher.doesNotMatch(expression, failureMessage: msg)
    if msg.actualValue == "" {
        msg.actualValue = "<\(stringify(expression.evaluate()))>"
    }
    return (pass, msg)
}

public struct Expectation<T> {
    let expression: Expression<T>

    public func verify(pass: Bool, _ message: FailureMessage) {
        NimbleAssertionHandler.assert(pass, message: message, location: expression.location)
    }

    /// Tests the actual value using a matcher to match.
    public func to<U where U: Matcher, U.ValueType == T>(matcher: U) {
        let (pass, msg) = expressionMatches(expression, matcher, to: "to")
        verify(pass, msg)
    }

    /// Tests the actual value using a matcher to not match.
    public func toNot<U where U: Matcher, U.ValueType == T>(matcher: U) {
        let (pass, msg) = expressionDoesNotMatch(expression, matcher, toNot: "to not")
        verify(pass, msg)
    }

    /// Tests the actual value using a matcher to not match.
    ///
    /// Alias to toNot().
    public func notTo<U where U: Matcher, U.ValueType == T>(matcher: U) {
        toNot(matcher)
    }

    // see:
    // - AsyncMatcherWrapper for extension
    // - NMBExpectation for Objective-C interface
}
