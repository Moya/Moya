/// Protocol to define the opaque type returned from a request
public protocol Cancellable {
    var cancelled: Bool { get }
    func cancel()
}

internal class CancellableWrapper: Cancellable {
    internal var innerCancellable: Cancellable = SimpleCancellable()

    var cancelled: Bool { return innerCancellable.cancelled }

    internal func cancel() {
        innerCancellable.cancel()
    }
}

internal class SimpleCancellable: Cancellable {
    var cancelled = false
    func cancel() {
        cancelled = true
    }
}
