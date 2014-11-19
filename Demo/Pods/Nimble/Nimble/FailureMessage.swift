import Foundation

@objc
public class FailureMessage {
    public var expected: String = "expected"
    public var actualValue: String? = "" // empty string -> use default; nil -> exclude
    public var to: String = "to"
    public var postfixMessage: String = "match"

    public init() {
    }

    var description : String {
        var value = "\(expected) \(to) \(postfixMessage)"
        if let actualValue = actualValue {
            value = "\(expected) \(actualValue) \(to) \(postfixMessage)"
        }
        var lines: [String] = (value as NSString).componentsSeparatedByString("\n") as [String]
        let whitespace = NSCharacterSet.whitespaceAndNewlineCharacterSet()
        lines = lines.map { line in line.stringByTrimmingCharactersInSet(whitespace) }
        return "".join(lines)
    }

    public func stringValue() -> String {
        var value = "\(expected) \(to) \(postfixMessage)"
        if let actualValue = actualValue {
            value = "\(expected) \(to) \(postfixMessage), got \(actualValue)"
        }
        var lines: [String] = (value as NSString).componentsSeparatedByString("\n") as [String]
        let whitespace = NSCharacterSet.whitespaceAndNewlineCharacterSet()
        lines = lines.map { line in line.stringByTrimmingCharactersInSet(whitespace) }
        return "".join(lines)
    }
}