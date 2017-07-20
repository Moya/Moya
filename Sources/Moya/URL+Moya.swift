import Foundation

public extension URL {

    /// Initialize URL from Moya's `TargetType`.
    init<T: TargetType>(target: T) {
        // When a TargetType's path is empty, URL.appendingPathComponent may introduce trailing /, which may not be wanted in some cases
        // See: https://github.com/Moya/Moya/pull/1053
        // And: https://github.com/Moya/Moya/issues/1049
        if target.path.isEmpty {
            self = target.baseURL
        } else {
            self = target.baseURL.appendingPathComponent(target.path)
        }
    }
}
