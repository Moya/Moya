import Foundation
import XCTest

class XCTestHandler : AssertionHandler {
    func assert(assertion: Bool, message: String, location: SourceLocation) {
        if !assertion {
            XCTFail(message, file: location.file, line: location.line)
        }
    }
}
