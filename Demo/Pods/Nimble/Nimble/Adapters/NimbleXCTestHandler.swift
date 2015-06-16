import Foundation
import XCTest

/// Default handler for Nimble. This assertion handler passes failures along to
/// XCTest.
public class NimbleXCTestHandler : AssertionHandler {
    public func assert(assertion: Bool, message: String, location: SourceLocation) {
        if !assertion {
            XCTFail(message, file: location.file, line: location.line)
        }
    }
}
