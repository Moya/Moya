import Foundation


struct FullMatcherWrapper<M, T where M: Matcher, M.ValueType == T>: Matcher {
    let matcher: M
    let to: String
    let toNot: String

    func matches(actualExpression: Expression<T>, failureMessage: FailureMessage) -> Bool {
        failureMessage.to = to
        return matcher.matches(actualExpression, failureMessage: failureMessage)
    }

    func doesNotMatch(actualExpression: Expression<T>, failureMessage: FailureMessage) -> Bool {
        failureMessage.to = toNot
        return matcher.doesNotMatch(actualExpression, failureMessage: failureMessage)
    }
}
