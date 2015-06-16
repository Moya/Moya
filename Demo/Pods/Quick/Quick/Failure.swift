import Foundation

@objc final class Failure {
    let callsite: Callsite
    let exception: NSException

    init(exception: NSException, callsite: Callsite) {
        self.exception = exception
        self.callsite = callsite
    }

    @objc(failureWithException:callsite:)
    class func failure(exception: NSException, callsite: Callsite) -> Failure {
        return Failure(exception: exception, callsite: callsite)
    }
}
