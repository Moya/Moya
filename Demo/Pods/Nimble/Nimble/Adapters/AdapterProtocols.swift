import Foundation

/// Protocol for the assertion handler that Nimble uses for all expectations.
public protocol AssertionHandler {
    func assert(assertion: Bool, message: FailureMessage, location: SourceLocation)
}

/// Global backing interface for assertions that Nimble creates.
/// Defaults to a private test handler that passes through to XCTest.
///
/// If XCTest is not available, you must assign your own assertion handler
/// before using any matchers, otherwise Nimble will abort the program.
///
/// @see AssertionHandler
public var NimbleAssertionHandler: AssertionHandler = { () -> AssertionHandler in
    return isXCTestAvailable() ? NimbleXCTestHandler() : NimbleXCTestUnavailableHandler()
}()
