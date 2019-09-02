#if canImport(Combine)

#if !COCOAPODS
import Moya
#endif

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public struct Publishable<Base> {
    /// Base object to extend.
    public let base: Base

    /// Creates extensions with base object.
    ///
    /// - parameter base: Base object.
    public init(_ base: Base) {
        self.base = base
    }
}

/// A type that has reactive extensions.
@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public protocol CombineCompatible {
    /// Extended type
    associatedtype ReactiveBase

    /// Reactive extensions.
    var combine: Publishable<ReactiveBase> { get set }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension CombineCompatible {

    /// Reactive extensions.
    public var combine: Publishable<Self> {
        get {
            return Publishable(self)
        }
        // swiftlint:disable:next unused_setter_value
        set {
            // this enables using Publishable to "mutate" base object
        }
    }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension MoyaProvider: CombineCompatible {}

#endif
