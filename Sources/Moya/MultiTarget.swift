import Foundation

/// A `TargetType` used to enable `MoyaProvider` to process multiple `TargetType`s.
public enum MultiTarget: TargetType {
    /// The embedded `TargetType`.
    case target(TargetType)

    public init(_ target: TargetType) {
        self = MultiTarget.target(target)
    }

    public var path: String {
        return target.path
    }

    public var baseURL: URL {
        return target.baseURL
    }

    public var method: Moya.Method {
        return target.method
    }

    public var parameters: [String: Any]? {
        return target.parameters
    }

    public var parameterEncoding: ParameterEncoding {
        return target.parameterEncoding
    }

    public var sampleData: Data {
        return target.sampleData
    }

    public var task: Task {
        return target.task
    }

    public var validate: Bool {
        return target.validate
    }

    /// The embedded `TargetType`.
    public var target: TargetType {
        switch self {
        case .target(let t): return t
        }
    }
}
