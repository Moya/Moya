//  Copyright (c) 2015 Rob Rix. All rights reserved.

/// An enum representing either a failure with an explanatory error, or a success with a result value.
public enum Result<T, Error: ErrorType>: ResultType, CustomStringConvertible, CustomDebugStringConvertible {
	case Success(T)
	case Failure(Error)

	// MARK: Constructors

	/// Constructs a success wrapping a `value`.
	public init(value: T) {
		self = .Success(value)
	}

	/// Constructs a failure wrapping an `error`.
	public init(error: Error) {
		self = .Failure(error)
	}

	/// Constructs a result from an Optional, failing with `Error` if `nil`
	public init(_ value: T?, @autoclosure failWith: () -> Error) {
		self = value.map(Result.Success) ?? .Failure(failWith())
	}

	/// Constructs a result from a function that uses `throw`, failing with `Error` if throws
	public init(@autoclosure _ f: () throws -> T) {
		do {
			self = .Success(try f())
		} catch {
			self = .Failure(error as! Error)
		}
	}
	

	// MARK: Deconstruction

	/// Returns the value from `Success` Results or `throw`s the error
	public func dematerialize() throws -> T {
		switch self {
		case let .Success(value):
			return value
		case let .Failure(error):
			throw error
		}
	}

	/// Case analysis for Result.
	///
	/// Returns the value produced by applying `ifFailure` to `Failure` Results, or `ifSuccess` to `Success` Results.
	public func analysis<Result>(@noescape ifSuccess ifSuccess: T -> Result, @noescape ifFailure: Error -> Result) -> Result {
		switch self {
		case let .Success(value):
			return ifSuccess(value)
		case let .Failure(value):
			return ifFailure(value)
		}
	}


	// MARK: Higher-order functions
	
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


	// MARK: CustomStringConvertible

	public var description: String {
		return analysis(
			ifSuccess: { ".Success(\($0))" },
			ifFailure: { ".Failure(\($0))" })
	}


	// MARK: CustomDebugStringConvertible

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

// MARK: - Derive result from failable closure

public func materialize<T>(@autoclosure f: () throws -> T) -> Result<T, NSError> {
	do {
		return .Success(try f())
	} catch {
		return .Failure(error as NSError)
	}
}

// MARK: - Cocoa API conveniences

/// Constructs a Result with the result of calling `try` with an error pointer.
///
/// This is convenient for wrapping Cocoa API which returns an object or `nil` + an error, by reference. e.g.:
///
///     Result.try { NSData(contentsOfURL: URL, options: .DataReadingMapped, error: $0) }
public func `try`<T>(function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, `try`: NSErrorPointer -> T?) -> Result<T, NSError> {
	var error: NSError?
	return `try`(&error).map(Result.Success) ?? .Failure(error ?? Result<T, NSError>.error(function: function, file: file, line: line))
}

/// Constructs a Result with the result of calling `try` with an error pointer.
///
/// This is convenient for wrapping Cocoa API which returns a `Bool` + an error, by reference. e.g.:
///
///     Result.try { NSFileManager.defaultManager().removeItemAtURL(URL, error: $0) }
public func `try`(function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, `try`: NSErrorPointer -> Bool) -> Result<(), NSError> {
	var error: NSError?
	return `try`(&error) ?
		.Success(())
	:	.Failure(error ?? Result<(), NSError>.error(function: function, file: file, line: line))
}


// MARK: - Operators

infix operator >>- {
	// Left-associativity so that chaining works like you’d expect, and for consistency with Haskell, Runes, swiftz, etc.
	associativity left

	// Higher precedence than function application, but lower than function composition.
	precedence 100
}

/// Returns the result of applying `transform` to `Success`es’ values, or re-wrapping `Failure`’s errors.
///
/// This is a synonym for `flatMap`.
public func >>- <T, U, Error> (result: Result<T, Error>, @noescape transform: T -> Result<U, Error>) -> Result<U, Error> {
	return result.flatMap(transform)
}


import Foundation
