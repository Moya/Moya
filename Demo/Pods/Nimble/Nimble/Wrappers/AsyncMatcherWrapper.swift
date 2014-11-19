import Foundation

struct AsyncMatcherWrapper<T, U where U: Matcher, U.ValueType == T>: Matcher {
    let fullMatcher: U
    let timeoutInterval: NSTimeInterval = 1
    let pollInterval: NSTimeInterval = 0.01

    func matches(actualExpression: Expression<T>, failureMessage: FailureMessage) -> Bool {
        let uncachedExpression = actualExpression.withoutCaching()
        let result = _pollBlock(pollInterval: pollInterval, timeoutInterval: timeoutInterval) {
            self.fullMatcher.matches(uncachedExpression, failureMessage: failureMessage)
        }
        switch (result) {
            case .Success: return true
            case .Failure: return false
            case .Timeout:
                failureMessage.postfixMessage += " (Stall on main thread)."
                return false
        }
    }

    func doesNotMatch(actualExpression: Expression<T>, failureMessage: FailureMessage) -> Bool  {
        let uncachedExpression = actualExpression.withoutCaching()
        let result = _pollBlock(pollInterval: pollInterval, timeoutInterval: timeoutInterval) {
            self.fullMatcher.doesNotMatch(uncachedExpression, failureMessage: failureMessage)
        }
        switch (result) {
            case .Success: return true
            case .Failure: return false
            case .Timeout:
                failureMessage.postfixMessage += " (Stall on main thread)."
                return false
        }
    }
}

extension Expectation {
    public func toEventually<U where U: Matcher, U.ValueType == T>(matcher: U, timeout: NSTimeInterval = 1, pollInterval: NSTimeInterval = 0.01) {
        to(AsyncMatcherWrapper(
            fullMatcher: matcher,
            timeoutInterval: timeout,
            pollInterval: pollInterval))
    }

    public func toEventuallyNot<U where U: Matcher, U.ValueType == T>(matcher: U, timeout: NSTimeInterval = 1, pollInterval: NSTimeInterval = 0.01) {
        toNot(AsyncMatcherWrapper(
            fullMatcher: matcher,
            timeoutInterval: timeout,
            pollInterval: pollInterval))
    }

    public func toEventually<U where U: BasicMatcher, U.ValueType == T>(matcher: U, timeout: NSTimeInterval = 1, pollInterval: NSTimeInterval = 0.01) {
        toEventually(
            FullMatcherWrapper(
                matcher: matcher,
                to: "to eventually",
                toNot: "to eventually not"),
            timeout: timeout,
            pollInterval: pollInterval)
    }

    public func toEventuallyNot<U where U: BasicMatcher, U.ValueType == T>(matcher: U, timeout: NSTimeInterval = 1, pollInterval: NSTimeInterval = 0.01) {
        toEventuallyNot(
            FullMatcherWrapper(
                matcher: matcher,
                to: "to eventually",
                toNot: "to eventually not"),
            timeout: timeout,
            pollInterval: pollInterval)
    }
}
