import Foundation

internal struct RaiseExceptionMatchResult {
    var success: Bool
    var nameFailureMessage: FailureMessage?
    var reasonFailureMessage: FailureMessage?
    var userInfoFailureMessage: FailureMessage?
}

internal func raiseExceptionMatcher(matches: (NSException?, SourceLocation) -> RaiseExceptionMatchResult) -> MatcherFunc<Any> {
    return MatcherFunc { actualExpression, failureMessage in
        failureMessage.actualValue = nil

        var exception: NSException?
        var capture = NMBExceptionCapture(handler: ({ e in
            exception = e
        }), finally: nil)

        capture.tryBlock {
            actualExpression.evaluate()
            return
        }

        let result = matches(exception, actualExpression.location)

        failureMessage.postfixMessage = "raise exception"

        if let nameFailureMessage = result.nameFailureMessage {
            failureMessage.postfixMessage += " with name \(nameFailureMessage.postfixMessage)"
        }
        if let reasonFailureMessage = result.reasonFailureMessage {
            failureMessage.postfixMessage += " with reason \(reasonFailureMessage.postfixMessage)"
        }
        if let userInfoFailureMessage = result.userInfoFailureMessage {
            failureMessage.postfixMessage += " with userInfo \(userInfoFailureMessage.postfixMessage)"
        }
        if result.nameFailureMessage == nil && result.reasonFailureMessage == nil
            && result.userInfoFailureMessage == nil {
                failureMessage.postfixMessage = "raise any exception"
        }

        return result.success
    }

}

// A Nimble matcher that succeeds when the actual expression raises an exception, which name,
// reason and userInfo match successfully with the provided matchers
public func raiseException(
    named: NonNilMatcherFunc<String>? = nil,
    reason: NonNilMatcherFunc<String>? = nil,
    userInfo: NonNilMatcherFunc<NSDictionary>? = nil) -> MatcherFunc<Any> {
        return raiseExceptionMatcher() { exception, location in

            var matches = exception != nil

            var nameFailureMessage: FailureMessage?
            if let nameMatcher = named {
                let wrapper = NonNilMatcherWrapper(NonNilBasicMatcherWrapper(nameMatcher))
                nameFailureMessage = FailureMessage()
                matches = wrapper.matches(
                    Expression(expression: { exception?.name },
                        location: location,
                        isClosure: false),
                    failureMessage: nameFailureMessage!) && matches
            }

            var reasonFailureMessage: FailureMessage?
            if let reasonMatcher = reason {
                let wrapper = NonNilMatcherWrapper(NonNilBasicMatcherWrapper(reasonMatcher))
                reasonFailureMessage = FailureMessage()
                matches = wrapper.matches(
                    Expression(expression: { exception?.reason },
                        location: location,
                        isClosure: false),
                    failureMessage: reasonFailureMessage!) && matches
            }

            var userInfoFailureMessage: FailureMessage?
            if let userInfoMatcher = userInfo {
                let wrapper = NonNilMatcherWrapper(NonNilBasicMatcherWrapper(userInfoMatcher))
                userInfoFailureMessage = FailureMessage()
                matches = wrapper.matches(
                    Expression(expression: { exception?.userInfo },
                        location: location,
                        isClosure: false),
                    failureMessage: userInfoFailureMessage!) && matches
            }

            return RaiseExceptionMatchResult(
                success: matches,
                nameFailureMessage: nameFailureMessage,
                reasonFailureMessage: reasonFailureMessage,
                userInfoFailureMessage: userInfoFailureMessage)
        }
}

/// A Nimble matcher that succeeds when the actual expression raises an exception with
/// the specified name, reason, and userInfo.
public func raiseException(#named: String, #reason: String, #userInfo: NSDictionary) -> MatcherFunc<Any> {
    return raiseException(named: equal(named), reason: equal(reason), userInfo: equal(userInfo))
}

/// A Nimble matcher that succeeds when the actual expression raises an exception with
/// the specified name and reason.
public func raiseException(#named: String, #reason: String) -> MatcherFunc<Any> {
    return raiseException(named: equal(named), reason: equal(reason))
}


/// A Nimble matcher that succeeds when the actual expression raises an exception with
/// the specified name.
public func raiseException(#named: String) -> MatcherFunc<Any> {
    return raiseException(named: equal(named))
}

@objc public class NMBObjCRaiseExceptionMatcher : NMBMatcher {
    var _name: String?
    var _reason: String?
    var _userInfo: NSDictionary?
    var _nameMatcher: NMBMatcher?
    var _reasonMatcher: NMBMatcher?
    var _userInfoMatcher: NMBMatcher?

    init(name: String?, reason: String?, userInfo: NSDictionary?) {
        _name = name
        _reason = reason
        _userInfo = userInfo
    }

    init(nameMatcher: NMBMatcher?, reasonMatcher: NMBMatcher?, userInfoMatcher: NMBMatcher?) {
        _nameMatcher = nameMatcher
        _reasonMatcher = reasonMatcher
        _userInfoMatcher = userInfoMatcher
    }

    public func matches(actualBlock: () -> NSObject!, failureMessage: FailureMessage, location: SourceLocation) -> Bool {
        let block: () -> Any? = ({ actualBlock(); return nil })
        let expr = Expression(expression: block, location: location)
        if _nameMatcher != nil || _reasonMatcher != nil || _userInfoMatcher != nil {
            return raiseExceptionMatcher() {
                exception, location in

                var matches = exception != nil

                var nameFailureMessage: FailureMessage?
                if let nameMatcher = self._nameMatcher {
                    nameFailureMessage = FailureMessage()
                    matches = nameMatcher.matches({ exception?.name },
                        failureMessage: nameFailureMessage!,
                        location: location) && matches
                }

                var reasonFailureMessage: FailureMessage?
                if let reasonMatcher = self._reasonMatcher {
                    reasonFailureMessage = FailureMessage()
                    matches = reasonMatcher.matches({ exception?.reason },
                        failureMessage: reasonFailureMessage!,
                        location: location) && matches
                }

                var userInfoFailureMessage: FailureMessage?
                if let userInfoMatcher = self._userInfoMatcher {
                    userInfoFailureMessage = FailureMessage()
                    matches = userInfoMatcher.matches({ exception?.userInfo },
                        failureMessage: userInfoFailureMessage!,
                        location: location) && matches
                }

                return RaiseExceptionMatchResult(
                    success: matches,
                    nameFailureMessage: nameFailureMessage,
                    reasonFailureMessage: reasonFailureMessage,
                    userInfoFailureMessage: userInfoFailureMessage)

            }.matches(expr, failureMessage: failureMessage)
        } else if let name = _name, reason = _reason, userInfo = _userInfo {
            return raiseException(named: name, reason: reason, userInfo: userInfo).matches(expr, failureMessage: failureMessage)
        } else if let name = _name, reason = _reason {
            return raiseException(named: name, reason: reason).matches(expr, failureMessage: failureMessage)
        } else if let name = _name {
            return raiseException(named: name).matches(expr, failureMessage: failureMessage)
        } else {
            return raiseException().matches(expr, failureMessage: failureMessage)
        }
    }

    public func doesNotMatch(actualBlock: () -> NSObject!, failureMessage: FailureMessage, location: SourceLocation) -> Bool {
        return !matches(actualBlock, failureMessage: failureMessage, location: location)
    }

    public var named: (name: String) -> NMBObjCRaiseExceptionMatcher {
        return ({ name in
            return NMBObjCRaiseExceptionMatcher(name: name, reason: self._reason, userInfo: self._userInfo)
        })
    }

    public var reason: (reason: String?) -> NMBObjCRaiseExceptionMatcher {
        return ({ reason in
            return NMBObjCRaiseExceptionMatcher(name: self._name, reason: reason, userInfo: self._userInfo)
        })
    }

    public var userInfo: (userInfo: NSDictionary?) -> NMBObjCRaiseExceptionMatcher {
        return ({ userInfo in
            return NMBObjCRaiseExceptionMatcher(name: self._name, reason: self._reason, userInfo: userInfo)
        })
    }

    public var withName: (nameMatcher: NMBMatcher) -> NMBObjCRaiseExceptionMatcher {
        return ({ nameMatcher in
            return NMBObjCRaiseExceptionMatcher(nameMatcher: nameMatcher,
                reasonMatcher: self._reasonMatcher, userInfoMatcher: self._userInfoMatcher)
        })
    }

    public var withReason: (reasonMatcher: NMBMatcher) -> NMBObjCRaiseExceptionMatcher {
        return ({ reasonMatcher in
            return NMBObjCRaiseExceptionMatcher(nameMatcher: self._nameMatcher,
                reasonMatcher: reasonMatcher, userInfoMatcher: self._userInfoMatcher)
        })
    }

    public var withUserInfo: (userInfoMatcher: NMBMatcher) -> NMBObjCRaiseExceptionMatcher {
        return ({ userInfoMatcher in
            return NMBObjCRaiseExceptionMatcher(nameMatcher: self._nameMatcher,
                reasonMatcher: self._reasonMatcher, userInfoMatcher: userInfoMatcher)
        })
    }
}

extension NMBObjCMatcher {
    public class func raiseExceptionMatcher() -> NMBObjCRaiseExceptionMatcher {
        return NMBObjCRaiseExceptionMatcher(name: nil, reason: nil, userInfo: nil)
    }
}
