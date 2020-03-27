import Foundation

/// Controls how stub responses are returned.
public struct StubBehavior {
    
    /// The delay with which the stubbed response should be received by the provider.
    let delay: TimeInterval
    
    /// The result to be received by the provider.
    let result: MoyaResult

    public init(delay: TimeInterval = 0, result: MoyaResult) {
        self.delay = delay
        self.result = result
    }
}
