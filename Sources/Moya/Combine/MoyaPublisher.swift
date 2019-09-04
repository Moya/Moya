#if canImport(Combine)

import Combine

// This should be already provided in Combine, but it's not.
// Ideally we would like to remove it, in favor of a framework-provided solution, ASAP.

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
internal class MoyaPublisher<Output>: Publisher {

    internal typealias Failure = MoyaError

    private class Subscription: Combine.Subscription {

        private let cancellable: Cancellable?

        init(subscriber: AnySubscriber<Output, MoyaError>, callback: @escaping (AnySubscriber<Output, MoyaError>) -> Cancellable?) {
            self.cancellable = callback(subscriber)
        }

        func request(_ demand: Subscribers.Demand) {
            // We don't care for the demand right now
        }

        func cancel() {
            cancellable?.cancel()
        }
    }

    private let callback: (AnySubscriber<Output, MoyaError>) -> Cancellable?

    init(callback: @escaping (AnySubscriber<Output, MoyaError>) -> Cancellable?) {
        self.callback = callback
    }

    internal func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        let subscription = Subscription(subscriber: AnySubscriber(subscriber), callback: callback)
        subscriber.receive(subscription: subscription)
    }
}

#endif
