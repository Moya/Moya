import Foundation

/// A `TargetType` used to enable `MoyaProvider` to process multiple `TargetType`s.
public enum MultiTarget: TargetType {
    /// The embedded `TargetType`.
    case target(TargetType)

    /// Initializes a `MultiTarget`.
    public init(_ target: TargetType) {
        self = MultiTarget.target(target)
    }

    /// The embedded target's base `URL`.
    public var path: String {
        return target.path
    }

    /// The baseURL of the embedded target.
    public var baseURL: URL {
        return target.baseURL
    }

    /// The HTTP method of the embedded target.
    public var method: Moya.Method {
        return target.method
    }

    /// The sampleData of the embedded target.
    public var sampleData: Data {
        return target.sampleData
    }

    /// The `Task` of the embedded target.
    public var task: Task {
        return target.task
    }

    /// A Boolean value determining whether the embedded target performs Alamofire validation.
    /// Defaults to `false`.
    public var validate: Bool {
        return target.validate
    }

    /// The headers of the embedded target.
    public var headers: [String: String]? {
        return target.headers
    }

    /// The embedded `TargetType`.
    public var target: TargetType {
        switch self {
        case .target(let t): return t
        }
    }
}
