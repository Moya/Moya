import Foundation

#if swift(>=5.5)

/// Type alias for Swift.Continuation.Task to resolve the conflict with Moya.Task and not needed hide `import Moya` from file header
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public typealias AsyncTask = _Concurrency.Task

#endif
