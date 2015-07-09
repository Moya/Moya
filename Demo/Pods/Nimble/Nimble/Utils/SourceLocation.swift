import Foundation


@objc public class SourceLocation : CustomStringConvertible {
    public let file: String
    public let line: UInt

    init() {
        file = "Unknown File"
        line = 0
    }

    init(file: String, line: UInt) {
        self.file = file
        self.line = line
    }

    public var description: String {
        return "\(file):\(line)"
    }
}
