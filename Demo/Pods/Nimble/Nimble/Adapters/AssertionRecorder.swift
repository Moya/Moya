import Foundation

public struct AssertionRecord {
    public let success: Bool
    public let message: String
    public let location: SourceLocation
}

public class AssertionRecorder : AssertionHandler {
    public var assertions = [AssertionRecord]()

    public init() {}

    public func assert(assertion: Bool, message: String, location: SourceLocation) {
        assertions.append(
            AssertionRecord(
                success: assertion,
                message: message,
                location: location))
    }
}

public func withAssertionHandler(recorder: AssertionHandler, closure: () -> Void) {
    let oldRecorder = CurrentAssertionHandler
    let capturer = NMBExceptionCapture(handler: nil, finally: ({
        CurrentAssertionHandler = oldRecorder
    }))
    CurrentAssertionHandler = recorder
    capturer.tryBlock {
        closure()
    }
}
