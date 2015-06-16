//  Copyright (c) 2014 Rob Rix. All rights reserved.

/// Wraps a type `T` in a reference type.
///
/// Typically this is used to work around limitations of value types (for example, the lack of codegen for recursive value types and type-parameterized enums with >1 case). It is also useful for sharing a single (presumably large) value without copying it.
public final class Box<T>: BoxType, Printable {
	/// Initializes a `Box` with the given value.
	public init(_ value: T) {
		self.value = value
	}


	/// Constructs a `Box` with the given `value`.
	public class func unit(value: T) -> Box<T> {
		return Box(value)
	}


	/// The (immutable) value wrapped by the receiver.
	public let value: T

	/// Constructs a new Box by transforming `value` by `f`.
	public func map<U>(@noescape f: T -> U) -> Box<U> {
		return Box<U>(f(value))
	}


	// MARK: Printable

	public var description: String {
		return toString(value)
	}
}
