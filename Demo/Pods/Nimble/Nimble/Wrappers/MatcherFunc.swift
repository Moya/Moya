import Foundation

public struct FullMatcherFunc<T>: Matcher {
    public let matcher: (Expression<T>, FailureMessage, Bool) -> Bool

    public init(_ matcher: (Expression<T>, FailureMessage, Bool) -> Bool) {
        self.matcher = matcher
    }

    public func matches(actualExpression: Expression<T>, failureMessage: FailureMessage) -> Bool {
        return matcher(actualExpression, failureMessage, false)
    }

    public func doesNotMatch(actualExpression: Expression<T>, failureMessage: FailureMessage) -> Bool {
        return !matcher(actualExpression, failureMessage, true)
    }
}

public struct MatcherFunc<T>: BasicMatcher {
    public let matcher: (Expression<T>, FailureMessage) -> Bool

    public init(_ matcher: (Expression<T>, FailureMessage) -> Bool) {
        self.matcher = matcher
    }

    public func matches(actualExpression: Expression<T>, failureMessage: FailureMessage) -> Bool {
        return matcher(actualExpression, failureMessage)
    }
}

public struct NonNilMatcherFunc<T>: NonNilBasicMatcher {
    public let matcher: (Expression<T>, FailureMessage) -> Bool

    public init(_ matcher: (Expression<T>, FailureMessage) -> Bool) {
        self.matcher = matcher
    }

    public func matches(actualExpression: Expression<T>, failureMessage: FailureMessage) -> Bool {
        return matcher(actualExpression, failureMessage)
    }
}

public func fullMatcherFromBasicMatcher<M: BasicMatcher>(matcher: M) -> FullMatcherFunc<M.ValueType> {
    return FullMatcherFunc { actualExpression, failureMessage, expectingToNotMatch in
        return matcher.matches(actualExpression, failureMessage: failureMessage) != expectingToNotMatch
    }
}

public func basicMatcherWithFailureMessage<M: NonNilBasicMatcher>(matcher: M, postprocessor: (FailureMessage) -> Void) -> NonNilMatcherFunc<M.ValueType> {
    return NonNilMatcherFunc<M.ValueType> { actualExpression, failureMessage in
        let result = matcher.matches(actualExpression, failureMessage: failureMessage)
        postprocessor(failureMessage)
        return result
    }
}
