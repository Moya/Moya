import Foundation

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

extension AnyEncodable {
    public var underlyingEncodable: Encodable {
        if let embeddedAnyEncodable = encodable as? AnyEncodable {
            return embeddedAnyEncodable.underlyingEncodable
        }
        return encodable
    }
}
