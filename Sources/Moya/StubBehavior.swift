import Foundation

/// Controls how stub responses are returned.
public struct StubBehavior {
    let delay: TimeInterval
    let result: MoyaResult

    public init(delay: TimeInterval = 0, result: MoyaResult) {
        self.delay = delay
        self.result = result
    }
}
