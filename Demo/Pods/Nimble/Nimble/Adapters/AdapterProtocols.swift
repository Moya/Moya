import Foundation

public protocol AssertionHandler {
    func assert(assertion: Bool, message: String, location: SourceLocation)
}

var CurrentAssertionHandler: AssertionHandler = XCTestHandler()

