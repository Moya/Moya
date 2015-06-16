import Foundation


struct BasicMatcherWrapper<M, T where M: BasicMatcher, M.ValueType == T>: Matcher {
    let matcher: M

    func matches(actualExpression: Expression<T>, failureMessage: FailureMessage) -> Bool {
        return matcher.matches(actualExpression, failureMessage: failureMessage)
    }

    func doesNotMatch(actualExpression: Expression<T>, failureMessage: FailureMessage) -> Bool {
        return !matcher.matches(actualExpression, failureMessage: failureMessage)
    }
}

extension Expectation {
    public func to<U where U: BasicMatcher, U.ValueType == T>(matcher: U) {
        to(FullMatcherWrapper(matcher: BasicMatcherWrapper(matcher: matcher), to: "to", toNot: "to not"))
    }

    public func toNot<U where U: BasicMatcher, U.ValueType == T>(matcher: U) {
        toNot(FullMatcherWrapper(matcher: BasicMatcherWrapper(matcher: matcher), to: "to", toNot: "to not"))
    }

    public func notTo<U where U: BasicMatcher, U.ValueType == T>(matcher: U) {
        toNot(matcher)
    }
}
