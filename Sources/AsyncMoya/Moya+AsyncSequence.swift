import Foundation
import Moya

#if swift(>=5.5)

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension AsyncSequence where Element == Result<ProgressResponse, MoyaError> {
    func forEach(_ body: (Element) async throws -> Void) async throws {
        for try await element in self {
            try await body(element)
        }
    }
}

#endif
