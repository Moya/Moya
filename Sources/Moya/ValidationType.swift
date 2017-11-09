import Foundation

/// Represents the way Alamofire's validation is used
public enum ValidationType {

	/// Validate success codes only (2xx)
	case successCodes

	/// Validate success codes and redirection codes (2xx and 3xx)
	case successAndRedirectionCodes

	/// Validate only the given status codes
	case customCodes([Int])
}

extension ValidationType {

	/// The list of HTTP status code to validate.
	public var statusCodes: [Int] {
		switch self {
		case .successCodes:
			return Array(200..<300)
		case .successAndRedirectionCodes:
			return Array(200..<400)
		case .customCodes(let codes):
			return codes
		}
	}
}

extension ValidationType : Equatable {

	public static func == (lhs: ValidationType, rhs: ValidationType) -> Bool {
		switch (lhs, rhs) {
		case (.successCodes, .successCodes),
			 (.successAndRedirectionCodes, .successAndRedirectionCodes):
			return true
		case (.customCodes(let c1), .customCodes(let c2)):
			return c1 == c2
		default:
			return false
		}
	}
}
