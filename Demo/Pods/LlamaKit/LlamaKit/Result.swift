/// Result
///
/// Container for a successful value (T) or a failure with an NSError
///

import Foundation

/// A success `Result` returning `value`
/// This form is preferred to `Result.Success(Box(value))` because it
// does not require dealing with `Box()`
public func success<T>(value: T) -> Result<T> {
  return .Success(Box(value))
}

/// A failure `Result` returning `error`
/// The default error is an empty one so that `failure()` is legal
/// To assign this to a variable, you must explicitly give a type.
/// Otherwise the compiler has no idea what `T` is. This form is preferred
/// to Result.Failure(error) because it provides a useful default.
/// For example:
///    let fail: Result<Int> = failure()
///
public func failure<T>(_ error: NSError = NSError(domain: "", code: 0, userInfo: nil)) -> Result<T> {
  return .Failure(error)
}

/// Container for a successful value (T) or a failure with an NSError
public enum Result<T> {
  case Success(Box<T>)
  case Failure(NSError)

  /// The successful value as an Optional
  public func value() -> T? {
    switch self {
    case .Success(let box): return box.unbox
    case .Failure(_): return nil
    }
  }

  /// The failing error as an Optional
  public func error() -> NSError? {
    switch self {
    case .Success(_): return nil
    case .Failure(let err): return err
    }
  }

  public func isSuccess() -> Bool {
    switch self {
    case .Success(_): return true
    case .Failure(_): return false
    }
  }

  /// Return a new result after applying a transformation to a successful value.
  /// Mapping a failure returns a new failure without evaluating the transform
  public func map<U>(transform: T -> U) -> Result<U> {
    switch self {
    case Success(let box):
      return .Success(Box(transform(box.unbox)))
    case Failure(let err):
      return .Failure(err)
    }
  }

  /// Return a new result after applying a transformation (that itself
  /// returns a result) to a successful value.
  /// Flat mapping a failure returns a new failure without evaluating the transform
  public func flatMap<U>(transform:T -> Result<U>) -> Result<U> {
    switch self {
    case Success(let value): return transform(value.unbox)
    case Failure(let error): return .Failure(error)
    }
  }
}

extension Result: Printable {
  public var description: String {
    switch self {
    case .Success(let box):
      return "Success: \(box.unbox)"
    case .Failure(let error):
      return "Failure: \(error)"
    }
  }
}

/// Note that while it is possible to use `==` on results that contain
/// an Equatable type, Result is not itself Equatable. This is because
/// T may not be Equatable, and there is no way in Swift to define protocol
/// conformance based on your specialization.
public func == <T: Equatable>(lhs: Result<T>, rhs: Result<T>) -> Bool {
  switch (lhs, rhs) {
  case (.Success(_), .Success(_)): return lhs.value() == rhs.value()
  case (.Success(_), .Failure(_)): return false
  case (.Failure(let lhsErr), .Failure(let rhsErr)): return lhsErr == rhsErr
  case (.Failure(_), .Success(_)): return false
  }
}

public func != <T: Equatable>(lhs: Result<T>, rhs: Result<T>) -> Bool {
  return !(lhs == rhs)
}

/// Failure coalescing
///    .Success(Box(42)) ?? 0 ==> 42
///    .Failure(NSError()) ?? 0 ==> 0
public func ??<T>(result: Result<T>, defaultValue: @autoclosure () -> T) -> T {
  switch result {
  case .Success(let value):
    return value.unbox
  case .Failure(let error):
    return defaultValue()
  }
}

//
// Box
//

/// Due to current swift limitations, we have to include this Box in Result.
/// Swift cannot handle an enum with multiple associated data (A, NSError) where one is of unknown size (A)
final public class Box<T> {
  public let unbox: T
  public init(_ value: T) { self.unbox = value }
}
