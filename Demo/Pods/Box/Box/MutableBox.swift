//  Copyright (c) 2014 Rob Rix. All rights reserved.

/// Wraps a type `T` in a mutable reference type.
///
/// While this, like `Box<T>` could be used to work around limitations of value types, it is much more useful for sharing a single mutable value such that mutations are shared.
///
/// As with all mutable state, this should be used carefully, for example as an optimization, rather than a default design choice. Most of the time, `Box<T>` will suffice where any `BoxType` is needed.
public final class MutableBox<T>: MutableBoxType, Printable {
	/// Initializes a `MutableBox` with the given value.
	public init(_ value: T) {
		self.value = value
	}

	/// The (mutable) value wrapped by the receiver.
	public var value: T

	/// Constructs a new MutableBox by transforming `value` by `f`.
	public func map<U>(@noescape f: T -> U) -> MutableBox<U> {
		return MutableBox<U>(f(value))
	}

	// MARK: Printable

	public var description: String {
		return toString(value)
	}
}
