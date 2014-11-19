import Foundation


struct FullMatcherWrapper<M, T where M: BasicMatcher, M.ValueType == T>: Matcher {
    let matcher: M
    let to: String
    let toNot: String

    func matches(actualExpression: Expression<T>, failureMessage: FailureMessage) -> Bool {
        failureMessage.to = to
        let pass = matcher.matches(actualExpression, failureMessage: failureMessage)
        return pass
    }

    func doesNotMatch(actualExpression: Expression<T>, failureMessage: FailureMessage) -> Bool {
        failureMessage.to = toNot
        let pass = matcher.matches(actualExpression, failureMessage: failureMessage)
        return !pass
    }
}

extension Expectation {
    public func to<U where U: BasicMatcher, U.ValueType == T>(matcher: U) {
        to(FullMatcherWrapper(matcher: matcher, to: "to", toNot: "to not"))
    }

    public func toNot<U where U: BasicMatcher, U.ValueType == T>(matcher: U) {
        toNot(FullMatcherWrapper(matcher: matcher, to: "to", toNot: "to not"))
    }

    public func notTo<U where U: BasicMatcher, U.ValueType == T>(matcher: U) {
        toNot(matcher)
    }
}
