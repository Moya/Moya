import Foundation

/// A data structure that stores information about an assertion when
/// AssertionRecorder is set as the Nimble assertion handler.
///
/// @see AssertionRecorder
/// @see AssertionHandler
public struct AssertionRecord {
    /// Whether the assertion succeeded or failed
    public let success: Bool
    /// The failure message the assertion would display on failure.
    public let message: String
    /// The source location the expectation occurred on.
    public let location: SourceLocation
}

/// An AssertionHandler that silently records assertions that Nimble makes.
/// This is useful for testing failure messages for matchers.
///
/// @see AssertionHandler
public class AssertionRecorder : AssertionHandler {
    /// All the assertions that were captured by this recorder
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

/// Allows you to temporarily replace the current Nimble assertion handler with
/// the one provided for the scope of the closure.
///
/// Once the closure finishes, then the original Nimble assertion handler is restored.
///
/// @see AssertionHandler
public func withAssertionHandler(tempAssertionHandler: AssertionHandler, closure: () -> Void) {
    let oldRecorder = NimbleAssertionHandler
    let capturer = NMBExceptionCapture(handler: nil, finally: ({
        NimbleAssertionHandler = oldRecorder
    }))
    NimbleAssertionHandler = tempAssertionHandler
    capturer.tryBlock {
        closure()
    }
}
