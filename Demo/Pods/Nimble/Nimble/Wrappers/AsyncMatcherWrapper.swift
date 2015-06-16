import Foundation

struct AsyncMatcherWrapper<T, U where U: Matcher, U.ValueType == T>: Matcher {
    let fullMatcher: U
    let timeoutInterval: NSTimeInterval
    let pollInterval: NSTimeInterval

    init(fullMatcher: U, timeoutInterval: NSTimeInterval = 1, pollInterval: NSTimeInterval = 0.01) {
      self.fullMatcher = fullMatcher
      self.timeoutInterval = timeoutInterval
      self.pollInterval = pollInterval
    }

    func matches(actualExpression: Expression<T>, failureMessage: FailureMessage) -> Bool {
        let uncachedExpression = actualExpression.withoutCaching()
        let result = pollBlock(pollInterval: pollInterval, timeoutInterval: timeoutInterval) {
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
        let result = pollBlock(pollInterval: pollInterval, timeoutInterval: timeoutInterval) {
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

private let toEventuallyRequiresClosureError = "expect(...).toEventually(...) requires an explicit closure (eg - expect { ... }.toEventually(...) )\nSwift 1.2 @autoclosure behavior has changed in an incompatible way for Nimble to function"


extension Expectation {
    public func toEventually<U where U: Matcher, U.ValueType == T>(matcher: U, timeout: NSTimeInterval = 1, pollInterval: NSTimeInterval = 0.01) {
        if expression.isClosure {
            to(AsyncMatcherWrapper(
                fullMatcher: FullMatcherWrapper(
                    matcher: matcher,
                    to: "to eventually",
                    toNot: "to eventually not"),
                timeoutInterval: timeout,
                pollInterval: pollInterval))
        } else {
            verify(false, toEventuallyRequiresClosureError)
        }
    }

    public func toEventuallyNot<U where U: Matcher, U.ValueType == T>(matcher: U, timeout: NSTimeInterval = 1, pollInterval: NSTimeInterval = 0.01) {
        if expression.isClosure {
            toNot(AsyncMatcherWrapper(
                fullMatcher: FullMatcherWrapper(
                    matcher: matcher,
                    to: "to eventually",
                    toNot: "to eventually not"),
                timeoutInterval: timeout,
                pollInterval: pollInterval))
        } else {
            verify(false, toEventuallyRequiresClosureError)
        }
    }

    public func toEventually<U where U: BasicMatcher, U.ValueType == T>(matcher: U, timeout: NSTimeInterval = 1, pollInterval: NSTimeInterval = 0.01) {
        toEventually(
            FullMatcherWrapper(
                matcher: BasicMatcherWrapper(matcher: matcher),
                to: "to eventually",
                toNot: "to eventually not"),
            timeout: timeout,
            pollInterval: pollInterval)
    }

    public func toEventuallyNot<U where U: BasicMatcher, U.ValueType == T>(matcher: U, timeout: NSTimeInterval = 1, pollInterval: NSTimeInterval = 0.01) {
        toEventuallyNot(
            FullMatcherWrapper(
                matcher: BasicMatcherWrapper(matcher: matcher),
                to: "to eventually",
                toNot: "to eventually not"),
            timeout: timeout,
            pollInterval: pollInterval)
    }

    public func toEventually<U where U: NonNilBasicMatcher, U.ValueType == T>(matcher: U, timeout: NSTimeInterval = 1, pollInterval: NSTimeInterval = 0.1) {
        toEventually(
            FullMatcherWrapper(
                matcher: NonNilMatcherWrapper(NonNilBasicMatcherWrapper(matcher)),
                to: "to eventually",
                toNot: "to eventually not"),
            timeout: timeout,
            pollInterval: pollInterval)
    }

    public func toEventuallyNot<U where U: NonNilBasicMatcher, U.ValueType == T>(matcher: U, timeout: NSTimeInterval = 1, pollInterval: NSTimeInterval = 0.1) {
        toEventuallyNot(
            FullMatcherWrapper(
                matcher: NonNilMatcherWrapper(NonNilBasicMatcherWrapper(matcher)),
                to: "to eventually",
                toNot: "to eventually not"),
            timeout: timeout,
            pollInterval: pollInterval)
    }
}
