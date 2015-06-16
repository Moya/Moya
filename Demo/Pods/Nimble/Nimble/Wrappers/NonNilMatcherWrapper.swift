struct NonNilMatcherWrapper<M: Matcher, T where M.ValueType == T>: Matcher {
    let matcher: M
    let nilMessage = " (use beNil() to match nils)"

    init(_ matcher: M) {
        self.matcher = matcher
    }

    func matches(actualExpression: Expression<T>, failureMessage: FailureMessage) -> Bool {
        let pass = matcher.matches(actualExpression, failureMessage: failureMessage)
        if actualExpression.evaluate() == nil {
            failureMessage.postfixActual = nilMessage
            return false
        }
        return pass
    }

    func doesNotMatch(actualExpression: Expression<T>, failureMessage: FailureMessage) -> Bool {
        let pass = matcher.doesNotMatch(actualExpression, failureMessage: failureMessage)
        if actualExpression.evaluate() == nil {
            failureMessage.postfixActual = nilMessage
            return false
        }
        return pass
    }
}

struct NonNilBasicMatcherWrapper<M, T where M: NonNilBasicMatcher, M.ValueType == T>: Matcher {
    let matcher: M

    init(_ matcher: M) {
        self.matcher = matcher
    }

    func matches(actualExpression: Expression<T>, failureMessage: FailureMessage) -> Bool {
        return matcher.matches(actualExpression, failureMessage: failureMessage)
    }

    func doesNotMatch(actualExpression: Expression<T>, failureMessage: FailureMessage) -> Bool {
        return !matcher.matches(actualExpression, failureMessage: failureMessage)
    }
}

extension Expectation {
    public func to<U where U: NonNilBasicMatcher, U.ValueType == T>(matcher: U) {
        to(FullMatcherWrapper(matcher: NonNilMatcherWrapper(NonNilBasicMatcherWrapper(matcher)), to: "to", toNot: "to not"))
    }

    public func toNot<U where U: NonNilBasicMatcher, U.ValueType == T>(matcher: U) {
        toNot(FullMatcherWrapper(matcher: NonNilMatcherWrapper(NonNilBasicMatcherWrapper(matcher)), to: "to", toNot: "to not"))
    }

    public func notTo<U where U: NonNilBasicMatcher, U.ValueType == T>(matcher: U) {
        toNot(matcher)
    }
}
