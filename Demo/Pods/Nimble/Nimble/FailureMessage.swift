import Foundation

/// Encapsulates the failure message that matchers can report to the end user.
///
/// This is shared state between Nimble and matchers that mutate this value.
@objc public class FailureMessage {
    public var expected: String = "expected"
    public var actualValue: String? = "" // empty string -> use default; nil -> exclude
    public var to: String = "to"
    public var postfixMessage: String = "match"
    public var postfixActual: String = ""

    public var stringValue: String {
        get {
            if let value = _stringValueOverride {
                return value
            } else {
                return computeStringValue()
            }
        }
        set {
            _stringValueOverride = newValue
        }
    }

    internal var _stringValueOverride: String?

    public init() {
    }

    public init(stringValue: String) {
        _stringValueOverride = stringValue
    }

    internal func stripNewlines(str: String) -> String {
        var lines: [String] = (str as NSString).componentsSeparatedByString("\n") as! [String]
        let whitespace = NSCharacterSet.whitespaceAndNewlineCharacterSet()
        lines = lines.map { line in line.stringByTrimmingCharactersInSet(whitespace) }
        return "".join(lines)
    }

    internal func computeStringValue() -> String {
        var value = "\(expected) \(to) \(postfixMessage)"
        if let actualValue = actualValue {
            value = "\(expected) \(to) \(postfixMessage), got \(actualValue)\(postfixActual)"
        }
        return stripNewlines(value)
    }
}