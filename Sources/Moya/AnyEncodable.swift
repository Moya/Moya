import Foundation

/// A simple type wrapping an Encodable to provide a workaround for errors
/// of kind `Protocol type 'Encodable' cannot conform to 'Encodable' because only concrete types can conform to protocols`
public struct AnyEncodable {

    private let encodable: Encodable

    public init(_ encodable: Encodable) {
        self.encodable = encodable
    }
}

extension AnyEncodable: Encodable {
    public func encode(to encoder: Encoder) throws {
        try encodable.encode(to: encoder)
    }
}

public extension AnyEncodable {
    var underlyingEncodable: Encodable {
        if let embeddedAnyEncodable = encodable as? AnyEncodable {
            return embeddedAnyEncodable.underlyingEncodable
        }
        return encodable
    }
}
