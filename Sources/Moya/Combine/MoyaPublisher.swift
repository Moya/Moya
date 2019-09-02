#if canImport(Combine)

import Combine

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
// I really hate that we have to use our own `Publisher` implementation...
// This really should be built into Combine.
internal class MoyaPublisher<Output>: Publisher {

    internal typealias Failure = MoyaError

    private class Subscription: Combine.Subscription {

        private let callback: (AnySubscriber<Output, MoyaError>) -> Cancellable?
        private let subscriber: AnySubscriber<Output, MoyaError>
        private let cancellable: Cancellable?

        init(subscriber: AnySubscriber<Output, MoyaError>, callback: @escaping (AnySubscriber<Output, MoyaError>) -> Cancellable?) {
            self.subscriber = subscriber
            self.callback = callback
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

    // We couldn't use `Just` as it's `Failure` type is `Never`, where we really want `MoyaError`.
    // So this is a workaround for now.
    init(just: @escaping (() throws -> Output)) {
        self.callback = { subscriber in
            do {
                let output = try just()
                _ = subscriber.receive(output)
                subscriber.receive(completion: .finished)
            } catch {
                if let error = error as? MoyaError {
                    subscriber.receive(completion: .failure(error))
                } else {
                    // The cast above should never fail, but just in case.
                    subscriber.receive(completion: .failure(MoyaError.underlying(error, nil)))
                }
            }
            return nil
        }
    }

    internal func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        let subscription = Subscription(subscriber: AnySubscriber(subscriber), callback: callback)
        subscriber.receive(subscription: subscription)
    }
}

#endif
