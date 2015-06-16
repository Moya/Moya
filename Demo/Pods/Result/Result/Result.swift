//  Copyright (c) 2015 Rob Rix. All rights reserved.

/// An enum representing either a failure with an explanatory error, or a success with a result value.
public enum Result<T, Error>: Printable, DebugPrintable {
	case Success(Box<T>)
	case Failure(Box<Error>)

	// MARK: Constructors

	/// Constructs a success wrapping a `value`.
	public init(value: T) {
		self = .Success(Box(value))
	}

	/// Constructs a failure wrapping an `error`.
	public init(error: Error) {
		self = .Failure(Box(error))
	}

	/// Constructs a result from an Optional, failing with `Error` if `nil`
	public init(_ value: T?, @autoclosure failWith: () -> Error) {
		self = value.map { .success($0) } ?? .failure(failWith())
	}

	/// Constructs a success wrapping a `value`.
	public static func success(value: T) -> Result {
		return Result(value: value)
	}

	/// Constructs a failure wrapping an `error`.
	public static func failure(error: Error) -> Result {
		return Result(error: error)
	}


	// MARK: Deconstruction

	/// Returns the value from `Success` Results, `nil` otherwise.
	public var value: T? {
		return analysis(ifSuccess: { $0 }, ifFailure: { _ in nil })
	}

	/// Returns the error from `Failure` Results, `nil` otherwise.
	public var error: Error? {
		return analysis(ifSuccess: { _ in nil }, ifFailure: { $0 })
	}

	/// Case analysis for Result.
	///
	/// Returns the value produced by applying `ifFailure` to `Failure` Results, or `ifSuccess` to `Success` Results.
	public func analysis<Result>(@noescape #ifSuccess: T -> Result, @noescape ifFailure: Error -> Result) -> Result {
		switch self {
		case let .Success(value):
			return ifSuccess(value.value)
		case let .Failure(value):
			return ifFailure(value.value)
		}
	}


	// MARK: Higher-order functions

	/// Returns a new Result by mapping `Success`es’ values using `transform`, or re-wrapping `Failure`s’ errors.
	public func map<U>(@noescape transform: T -> U) -> Result<U, Error> {
		return flatMap { .success(transform($0)) }
	}

	/// Returns the result of applying `transform` to `Success`es’ values, or re-wrapping `Failure`’s errors.
	public func flatMap<U>(@noescape transform: T -> Result<U, Error>) -> Result<U, Error> {
		return analysis(
			ifSuccess: transform,
			ifFailure: Result<U, Error>.failure)
	}
	
	/// Returns `self.value` if this result is a .Success, or the given value otherwise. Equivalent with `??`
	public func recover(@autoclosure value: () -> T) -> T {
		return self.value ?? value()
	}
	
	/// Returns this result if it is a .Success, or the given result otherwise. Equivalent with `??`
	public func recoverWith(@autoclosure result: () -> Result<T,Error>) -> Result<T,Error> {
		return analysis(
			ifSuccess: { _ in self },
			ifFailure: { _ in result() })
	}


	// MARK: Errors

	/// The domain for errors constructed by Result.
	public static var errorDomain: String { return "com.antitypical.Result" }

	/// The userInfo key for source functions in errors constructed by Result.
	public static var functionKey: String { return "\(errorDomain).function" }

	/// The userInfo key for source file paths in errors constructed by Result.
	public static var fileKey: String { return "\(errorDomain).file" }

	/// The userInfo key for source file line numbers in errors constructed by Result.
	public static var lineKey: String { return "\(errorDomain).line" }

	/// Constructs an error.
	public static func error(message: String? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) -> NSError {
		var userInfo: [String: AnyObject] = [
			functionKey: function,
			fileKey: file,
			lineKey: line,
		]

		if let message = message {
			userInfo[NSLocalizedDescriptionKey] = message
		}

		return NSError(domain: errorDomain, code: 0, userInfo: userInfo)
	}


	// MARK: Printable

	public var description: String {
		return analysis(
			ifSuccess: { ".Success(\($0))" },
			ifFailure: { ".Failure(\($0))" })
	}


	// MARK: DebugPrintable

	public var debugDescription: String {
		return description
	}
}


/// Returns `true` if `left` and `right` are both `Success`es and their values are equal, or if `left` and `right` are both `Failure`s and their errors are equal.
public func == <T: Equatable, Error: Equatable> (left: Result<T, Error>, right: Result<T, Error>) -> Bool {
	if let left = left.value, right = right.value {
		return left == right
	} else if let left = left.error, right = right.error {
		return left == right
	}
	return false
}

/// Returns `true` if `left` and `right` represent different cases, or if they represent the same case but different values.
public func != <T: Equatable, Error: Equatable> (left: Result<T, Error>, right: Result<T, Error>) -> Bool {
	return !(left == right)
}


/// Returns the value of `left` if it is a `Success`, or `right` otherwise. Short-circuits.
public func ?? <T, Error> (left: Result<T, Error>, @autoclosure right: () -> T) -> T {
	return left.recover(right())
}

/// Returns `left` if it is a `Success`es, or `right` otherwise. Short-circuits.
public func ?? <T, Error> (left: Result<T, Error>, @autoclosure right: () -> Result<T, Error>) -> Result<T, Error> {
	return left.recoverWith(right())
}


// MARK: - Cocoa API conveniences

/// Constructs a Result with the result of calling `try` with an error pointer.
///
/// This is convenient for wrapping Cocoa API which returns an object or `nil` + an error, by reference. e.g.:
///
///     Result.try { NSData(contentsOfURL: URL, options: .DataReadingMapped, error: $0) }
public func try<T>(function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, try: NSErrorPointer -> T?) -> Result<T, NSError> {
	var error: NSError?
	return try(&error).map(Result.success) ?? Result.failure(error ?? Result<T, NSError>.error(function: function, file: file, line: line))
}

/// Constructs a Result with the result of calling `try` with an error pointer.
///
/// This is convenient for wrapping Cocoa API which returns a `Bool` + an error, by reference. e.g.:
///
///     Result.try { NSFileManager.defaultManager().removeItemAtURL(URL, error: $0) }
public func try(function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, try: NSErrorPointer -> Bool) -> Result<(), NSError> {
	var error: NSError?
	return try(&error) ?
		.success(())
	:	.failure(error ?? Result<(), NSError>.error(function: function, file: file, line: line))
}


// MARK: - Operators

infix operator >>- {
	// Left-associativity so that chaining works like you’d expect, and for consistency with Haskell, Runes, swiftz, etc.
	associativity left

	// Higher precedence than function application, but lower than function composition.
	precedence 100
}

infix operator &&& {
	/// Same associativity as &&.
	associativity left

	/// Same precedence as &&.
	precedence 120
}

/// Returns the result of applying `transform` to `Success`es’ values, or re-wrapping `Failure`’s errors.
///
/// This is a synonym for `flatMap`.
public func >>- <T, U, Error> (result: Result<T, Error>, @noescape transform: T -> Result<U, Error>) -> Result<U, Error> {
	return result.flatMap(transform)
}

/// Returns a Result with a tuple of `left` and `right` values if both are `Success`es, or re-wrapping the error of the earlier `Failure`.
public func &&& <T, U, Error> (left: Result<T, Error>, @autoclosure right: () -> Result<U, Error>) -> Result<(T, U), Error> {
	return left.flatMap { left in right().map { right in (left, right) } }
}


import Box
import Foundation
