/// A convenience API to build matchers that allow full control over
/// to() and toNot() match cases.
///
/// The final bool argument in the closure is if the match is for negation.
///
/// You may use this when implementing your own custom matchers.
///
/// Use the Matcher protocol instead of this type to accept custom matchers as
/// input parameters.
/// @see allPass for an example that uses accepts other matchers as input.
public struct FullMatcherFunc<T>: Matcher {
    public let matcher: (Expression<T>, FailureMessage, Bool) -> Bool

    public init(_ matcher: (Expression<T>, FailureMessage, Bool) -> Bool) {
        self.matcher = matcher
    }

    public func matches(actualExpression: Expression<T>, failureMessage: FailureMessage) -> Bool {
        return matcher(actualExpression, failureMessage, false)
    }

    public func doesNotMatch(actualExpression: Expression<T>, failureMessage: FailureMessage) -> Bool {
        return matcher(actualExpression, failureMessage, true)
    }
}

/// A convenience API to build matchers that don't need special negation
/// behavior. The toNot() behavior is the negation of to().
///
/// @see NonNilMatcherFunc if you prefer to have this matcher fail when nil
///                        values are recieved in an expectation.
///
/// You may use this when implementing your own custom matchers.
///
/// Use the Matcher protocol instead of this type to accept custom matchers as
/// input parameters.
/// @see allPass for an example that uses accepts other matchers as input.
public struct MatcherFunc<T>: Matcher {
    public let matcher: (Expression<T>, FailureMessage) -> Bool

    public init(_ matcher: (Expression<T>, FailureMessage) -> Bool) {
        self.matcher = matcher
    }

    public func matches(actualExpression: Expression<T>, failureMessage: FailureMessage) -> Bool {
        return matcher(actualExpression, failureMessage)
    }

    public func doesNotMatch(actualExpression: Expression<T>, failureMessage: FailureMessage) -> Bool {
        return !matcher(actualExpression, failureMessage)
    }
}

/// A convenience API to build matchers that don't need special negation
/// behavior. The toNot() behavior is the negation of to().
///
/// Unlike MatcherFunc, this will always fail if an expectation contains nil.
/// This applies regardless of using to() or toNot().
///
/// You may use this when implementing your own custom matchers.
///
/// Use the Matcher protocol instead of this type to accept custom matchers as
/// input parameters.
/// @see allPass for an example that uses accepts other matchers as input.
public struct NonNilMatcherFunc<T>: Matcher {
    public let matcher: (Expression<T>, FailureMessage) -> Bool

    public init(_ matcher: (Expression<T>, FailureMessage) -> Bool) {
        self.matcher = matcher
    }

    public func matches(actualExpression: Expression<T>, failureMessage: FailureMessage) -> Bool {
        let pass = matcher(actualExpression, failureMessage)
        if attachNilErrorIfNeeded(actualExpression, failureMessage: failureMessage) {
            return false
        }
        return pass
    }

    public func doesNotMatch(actualExpression: Expression<T>, failureMessage: FailureMessage) -> Bool {
        let pass = !matcher(actualExpression, failureMessage)
        if attachNilErrorIfNeeded(actualExpression, failureMessage: failureMessage) {
            return false
        }
        return pass
    }

    internal func attachNilErrorIfNeeded(actualExpression: Expression<T>, failureMessage: FailureMessage) -> Bool {
        if actualExpression.evaluate() == nil {
            failureMessage.postfixActual = " (use beNil() to match nils)"
            return true
        }
        return false
    }
}
